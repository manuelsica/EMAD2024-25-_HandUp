# server.py
import eventlet
from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model
import logging
import sys
from PIL import Image, ExifTags
import io
import random
import string
import re
import google.generativeai as genai
from supabase import create_client, Client
import bcrypt  # Per l'hashing delle password
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity
)
from flask_socketio import SocketIO, emit, join_room, leave_room, disconnect

# Configura il logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configurazione Flask
app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, allow_headers=["Content-Type", "Authorization"])

# Configura la chiave segreta per JWT
app.config['JWT_SECRET_KEY'] = 'V^8pZ4!kF#2sX@uJ9$L1mB&dR5eT3yC8oQ'  # Sostituisci con una chiave segreta sicura
jwt = JWTManager(app)

# Configura le credenziali di Supabase
SUPABASE_URL = "https://nrgzyxhkkuselsgbfzcq.supabase.co"  # Sostituisci con il tuo URL Supabase
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5yZ3p5eGhra3VzZWxzZ2JmemNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU5NDQ5MzIsImV4cCI6MjA1MTUyMDkzMn0.eX64nn7VpFqiPohWTRG_jk2sOPpsPMoKWxop5DN53-o"  # Sostituisci con la tua chiave API Supabase

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Configura la chiave API per Gemini e carica il modello generativo
genai.configure(api_key="")  # Sostituisci con la tua chiave API Gemini
generative_model = genai.GenerativeModel("gemini-1.5-flash")
logger.info("Modello GenerativeModel di Gemini caricato con successo.")

# Carica il modello di riconoscimento dei segni
model_path = 'model_trained_100_cell.h5'  # Sostituisci con il percorso del tuo modello

if model_path.endswith('.h5'):
    try:
        model = load_model(model_path)
        model_type = 'h5'
        logger.info("Modello Keras (.h5) caricato con successo.")
    except Exception as e:
        logger.error(f"Errore nel caricamento del modello Keras (.h5): {e}")
        sys.exit()
elif model_path.endswith('.tflite'):
    try:
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        model_type = 'tflite'
        logger.info("Modello TensorFlow Lite (.tflite) caricato con successo.")
    except Exception as e:
        logger.error(f"Errore nel caricamento del modello TensorFlow Lite (.tflite): {e}")
        sys.exit()
else:
    logger.error("Formato del modello non supportato. Usa un file .h5 o .tflite.")
    sys.exit()

# Inizializza MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=2, min_detection_confidence=0.5)

# Mappa 0-25 a A-Z
labels_dict = {i: chr(65 + i) for i in range(26)}

# Funzione per correggere l'orientamento dell'immagine
def correct_image_orientation(image_data, platform):
    try:
        img_pil = Image.open(io.BytesIO(image_data))
        for orientation in ExifTags.TAGS.keys():
            if ExifTags.TAGS[orientation] == 'Orientation':
                break
        exif = img_pil._getexif()
        if exif is not None:
            orientation = exif.get(orientation)
            if orientation == 3:
                img_pil = img_pil.rotate(180, expand=True)
            elif orientation == 6:
                img_pil = img_pil.rotate(270, expand=True)
            elif orientation == 8:
                img_pil = img_pil.rotate(90, expand=True)
        if platform == 'android':
            width, height = img_pil.size
            if width > height:
                img_pil = img_pil.rotate(90, expand=True)
        return np.array(img_pil)
    except Exception as e:
        logger.error(f"Errore durante la correzione dell'orientamento: {e}")
        return None

# Funzione per predire con modello Keras (.h5)
def predict_with_h5_model(processed_data):
    try:
        input_length = model.input_shape[1]
        processed_data = np.array(processed_data).reshape(1, input_length)
        prediction = model.predict(processed_data)
        predicted_index = np.argmax(prediction)
        confidence = float(np.max(prediction)) * 100
        predicted_character = labels_dict.get(predicted_index, '')
        return predicted_character, confidence
    except Exception as e:
        logger.error(f"Errore nella predizione con modello Keras: {e}")
        return "", 0.0

# Funzione per predire con modello TensorFlow Lite (.tflite)
def predict_with_tflite_model(processed_data):
    try:
        input_length = input_details[0]['shape'][1]
        processed_data = np.array(processed_data).reshape(1, input_length).astype(np.float32)
        interpreter.set_tensor(input_details[0]['index'], processed_data)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])
        predicted_index = np.argmax(output_data)
        confidence = float(np.max(output_data)) * 100
        predicted_character = labels_dict.get(predicted_index, '')
        return predicted_character, confidence
    except Exception as e:
        logger.error(f"Errore nella predizione con modello TensorFlow Lite: {e}")
        return "", 0.0

# Configura SocketIO
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

# Data structures per gestire le lobby (in memoria per semplicità)
# In un'applicazione di produzione, considera di usare un database persistente
lobbies = {}
users_in_lobbies = {}

# Helper per generare un ID univoco per le lobby
def generate_lobby_id(length=6):
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))

# Socket.IO Events
@socketio.on('connect')
@jwt_required()
def handle_connect():
    current_user_id = get_jwt_identity()
    logger.info(f"Utente {current_user_id} connesso via SocketIO.")
    emit('connected', {'message': 'Connesso al server SocketIO.'})
    # Aggiungi l'utente alla lista di utenti connessi se necessario

@socketio.on('disconnect')
def handle_disconnect():
    logger.info("Un utente si è disconnesso.")
    # Rimuovi l'utente dalla lista di utenti connessi e dalle lobby se necessario

@socketio.on('create_lobby')
@jwt_required()
def handle_create_lobby(data):
    try:
        current_user_id = get_jwt_identity()
        lobby_name = data.get('lobby_name')
        lobby_type = data.get('type')
        num_players = data.get('num_players')
        password = data.get('password', None)

        if not lobby_name or not lobby_type or not num_players:
            emit('error', {'error': 'Campi mancanti per la creazione della lobby.'})
            return

        lobby_id = generate_lobby_id()
        lobbies[lobby_id] = {
            'id': lobby_id,
            'name': lobby_name,
            'type': lobby_type,
            'num_players': num_players,
            'current_players': 1,
            'creator': current_user_id,
            'is_locked': bool(password),
            'password': password,
            'players': [current_user_id],
        }

        join_room(lobby_id)
        users_in_lobbies[current_user_id] = lobby_id

        emit('lobby_created', {'lobby': lobbies[lobby_id]}, room=lobby_id)
        emit('update_lobbies', {'lobbies': list(lobbies.values())}, broadcast=True)

        logger.info(f"Lobby {lobby_id} creata da utente {current_user_id}.")
    except Exception as e:
        logger.error(f"Errore nella creazione della lobby: {e}")
        emit('error', {'error': 'Errore nella creazione della lobby.'})

@socketio.on('join_lobby')
@jwt_required()
def handle_join_lobby(data):
    try:
        current_user_id = get_jwt_identity()
        lobby_id = data.get('lobby_id')
        password = data.get('password', None)

        if not lobby_id:
            emit('error', {'error': 'ID della lobby mancante.'})
            return

        if lobby_id not in lobbies:
            emit('error', {'error': 'Lobby non trovata.'})
            return

        lobby = lobbies[lobby_id]

        if lobby['current_players'] >= lobby['num_players']:
            emit('error', {'error': 'Lobby piena.'})
            return

        if lobby['is_locked']:
            if not password or password != lobby['password']:
                emit('error', {'error': 'Password della lobby errata.'})
                return

        # Aggiungi l'utente alla lobby
        lobby['current_players'] += 1
        lobby['players'].append(current_user_id)
        join_room(lobby_id)
        users_in_lobbies[current_user_id] = lobby_id

        emit('joined_lobby', {'lobby': lobby}, room=lobby_id)
        emit('player_joined', {'user_id': current_user_id}, room=lobby_id)
        emit('update_lobbies', {'lobbies': list(lobbies.values())}, broadcast=True)

        logger.info(f"Utente {current_user_id} si è unito alla lobby {lobby_id}.")
    except Exception as e:
        logger.error(f"Errore nell'unirsi alla lobby: {e}")
        emit('error', {'error': 'Errore nell\'unirsi alla lobby.'})

@socketio.on('leave_lobby')
@jwt_required()
def handle_leave_lobby(data):
    try:
        current_user_id = get_jwt_identity()
        lobby_id = data.get('lobby_id')

        if not lobby_id or lobby_id not in lobbies:
            emit('error', {'error': 'Lobby non valida.'})
            return

        lobby = lobbies[lobby_id]

        if current_user_id not in lobby['players']:
            emit('error', {'error': 'Utente non parte della lobby.'})
            return

        # Rimuovi l'utente dalla lobby
        lobby['current_players'] -= 1
        lobby['players'].remove(current_user_id)
        leave_room(lobby_id)
        users_in_lobbies.pop(current_user_id, None)

        emit('player_left', {'user_id': current_user_id}, room=lobby_id)
        emit('update_lobbies', {'lobbies': list(lobbies.values())}, broadcast=True)

        logger.info(f"Utente {current_user_id} ha lasciato la lobby {lobby_id}.")

        # Se la lobby è vuota, rimuovila
        if lobby['current_players'] == 0:
            del lobbies[lobby_id]
            emit('lobby_closed', {'lobby_id': lobby_id}, broadcast=True)
            logger.info(f"Lobby {lobby_id} chiusa perché vuota.")
    except Exception as e:
        logger.error(f"Errore nel lasciare la lobby: {e}")
        emit('error', {'error': 'Errore nel lasciare la lobby.'})

@socketio.on('start_game')
@jwt_required()
def handle_start_game(data):
    try:
        current_user_id = get_jwt_identity()
        lobby_id = data.get('lobby_id')

        if not lobby_id or lobby_id not in lobbies:
            emit('error', {'error': 'Lobby non valida.'})
            return

        lobby = lobbies[lobby_id]

        if lobby['creator'] != current_user_id:
            emit('error', {'error': 'Solo il creatore della lobby può avviare il gioco.'})
            return

        # Logica per avviare il gioco
        # Puoi personalizzare questo evento in base alle tue necessità
        emit('game_started', {'message': 'Il gioco è iniziato!'}, room=lobby_id)
        logger.info(f"Il gioco nella lobby {lobby_id} è stato avviato dal creatore {current_user_id}.")
    except Exception as e:
        logger.error(f"Errore nell'avviare il gioco: {e}")
        emit('error', {'error': 'Errore nell\'avviare il gioco.'})

@socketio.on('get_lobbies')
@jwt_required()
def handle_get_lobbies():
    try:
        emit('update_lobbies', {'lobbies': list(lobbies.values())})
    except Exception as e:
        logger.error(f"Errore nel recuperare le lobby: {e}")
        emit('error', {'error': 'Errore nel recuperare le lobby.'})

# Endpoint per predire la lettera dalla foto
@app.route('/predict/', methods=['POST'])
@jwt_required()
def predict():
    try:
        data = request.get_json()
        if 'image' not in data or 'platform' not in data:
            return jsonify({'error': "Nessun campo 'image' o 'platform' trovato nella richiesta."}), 400

        platform = data['platform']
        image_data = base64.b64decode(data['image'])
        corrected_image = correct_image_orientation(image_data, platform)
        if corrected_image is None:
            return jsonify({'error': "Impossibile correggere l'orientamento dell'immagine."}), 400

        frame = cv2.cvtColor(corrected_image, cv2.COLOR_RGB2BGR)
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = hands.process(frame_rgb)

        predictions = []

        if results.multi_hand_landmarks:
            for idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
                data_aux = []
                x_ = [landmark.x for landmark in hand_landmarks.landmark]
                y_ = [landmark.y for landmark in hand_landmarks.landmark]

                min_x = min(x_)
                min_y = min(y_)

                for landmark in hand_landmarks.landmark:
                    data_aux.append(landmark.x - min_x)
                    data_aux.append(landmark.y - min_y)

                input_length = model.input_shape[1] if model_type == 'h5' else input_details[0]['shape'][1]
                if len(data_aux) < input_length:
                    data_aux += [0] * (input_length - len(data_aux))
                else:
                    data_aux = data_aux[:input_length]

                if model_type == 'h5':
                    predicted_character, confidence = predict_with_h5_model(data_aux)
                elif model_type == 'tflite':
                    predicted_character, confidence = predict_with_tflite_model(data_aux)
                else:
                    predicted_character, confidence = "", 0.0

                hand_type = "Right Hand" if results.multi_handedness[idx].classification[0].label == "Right" else "Left Hand"
                predictions.append({
                    'hand': idx + 1,
                    'hand_type': hand_type,
                    'character': predicted_character,
                    'confidence': confidence
                })

        return jsonify({'predictions': predictions}), 200
    except Exception as e:
        logger.error(f"Errore durante la predizione: {e}")
        return jsonify({'error': str(e)}), 500

# Funzione per generare le parole utilizzando il modello generativo
def genera_parole(modalita):
    if modalita == "facile":
        lunghezza_min, lunghezza_max = 3, 5
    elif modalita == "medio":
        lunghezza_min, lunghezza_max = 6, 8
    elif modalita == "difficile":
        lunghezza_min, lunghezza_max = 8, 20
    else:
        return []

    prompt = (
        f"Genera una lista di 10 parole uniche e significative. "
        f"Le parole devono avere una lunghezza compresa tra {lunghezza_min} e {lunghezza_max} caratteri. "
        f"Le parole non devono contenere accenti (come à, è, ò, ù) o caratteri speciali come simboli o numeri. "
        f"Rispondi in formato lista numerata con parole di senso compiuto e che esistono."
    )
    logger.info(f"Prompt generato: {prompt}")
    try:
        response = generative_model.generate_content(prompt)
        logger.info(f"Risposta da Gemini: {response.text}")

        # Usa una regex per estrarre le parole dalla lista numerata
        pattern = r"^\d+\.\s*(\w+)"  # Corrisponde a "1. Parola"
        matches = re.findall(pattern, response.text, re.MULTILINE)
        parole_filtrate = [p for p in matches if lunghezza_min <= len(p) <= lunghezza_max]
        return parole_filtrate[:10]
    except Exception as e:
        logger.error(f"Errore nella generazione delle parole: {e}")
        return []

# Endpoint per generare le parole
@app.route('/generate-words', methods=['POST'])
@jwt_required()
def generate_words():
    try:
        data = request.get_json()
        modalita = data.get("modalita")
        if modalita not in ["facile", "medio", "difficile"]:
            return jsonify({"error": "Modalità non valida"}), 400

        parole = genera_parole(modalita)
        return jsonify({"words": parole}), 200
    except Exception as e:
        logger.error(f"Errore nella generazione delle parole: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        confirm_password = data.get('confirm_password')

        # Validazione dei campi
        if not username or not email or not password or not confirm_password:
            return jsonify({'error': 'Tutti i campi sono obbligatori.'}), 400

        if password != confirm_password:
            return jsonify({'error': 'Le password non corrispondono.'}), 400

        # Validazione dell'email
        email_regex = r"[^@]+@[^@]+\.[^@]+"
        if not re.match(email_regex, email):
            return jsonify({'error': 'Email non valida.'}), 400

        # Controllo se l'email è già registrata
        existing_user = supabase.table('users').select('id').eq('email', email).execute()
        if existing_user.data and len(existing_user.data) > 0:
            return jsonify({'error': 'Email già registrata.'}), 400

        # Hash della password
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        # Inserimento del nuovo utente nel database
        new_user = supabase.table('users').insert({
            'username': username,
            'email': email,
            'password': hashed_password,
            'points': 0  # Punti iniziali
        }).execute()

        # Controllo del successo dell'inserimento
        if new_user.data and len(new_user.data) > 0:
            # Creazione del token JWT
            user_id = new_user.data[0].get('id')
            access_token = create_access_token(identity=user_id)
            username = new_user.data[0].get('username')
            points = new_user.data[0].get('points', 0)

            return jsonify({
                'message': 'Registrazione avvenuta con successo.',
                'access_token': access_token,
                'username': username,
                'points': points
            }), 201

        logger.error("Errore durante l'inserimento dell'utente.")
        return jsonify({'error': 'Errore durante la registrazione.'}), 500

    except Exception as e:
        logger.error(f"Errore nella registrazione: {e}")
        return jsonify({'error': 'Errore interno del server.'}), 500

# Endpoint per il login degli utenti
@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        # Validazione dei campi
        if not email or not password:
            return jsonify({'error': 'Email e password sono obbligatorie.'}), 400

        # Validazione dell'email
        email_regex = r"[^@]+@[^@]+\.[^@]+"
        if not re.match(email_regex, email):
            return jsonify({'error': 'Email non valida.'}), 400

        # Recupero dell'utente dal database
        user_response = supabase.table('users').select('*').eq('email', email).execute()
        logger.info(f"Risposta Supabase (login): {user_response}")

        if not user_response.data or len(user_response.data) == 0:
            return jsonify({'error': 'Email o password errate.'}), 401

        user = user_response.data[0]
        stored_hashed_password = user.get('password')

        if not stored_hashed_password:
            logger.error("Password non trovata per l'utente.")
            return jsonify({'error': 'Errore durante il login.'}), 500

        # Verifica della password
        if not bcrypt.checkpw(password.encode('utf-8'), stored_hashed_password.encode('utf-8')):
            return jsonify({'error': 'Email o password errate.'}), 401

        # Creazione del token JWT
        access_token = create_access_token(identity=user['id'])  # Usa un identificatore unico, ad esempio l'ID dell'utente

        # Recupero di username e points
        username = user.get('username', 'Username')
        points = user.get('points', 0)

        return jsonify({
            'message': 'Login effettuato con successo.',
            'access_token': access_token,
            'username': username,
            'points': points
        }), 200

    except Exception as e:
        logger.error(f"Errore nel login: {e}")
        return jsonify({'error': 'Errore interno del server.'}), 500

# Endpoint per ottenere i dettagli dell'utente
@app.route('/user', methods=['GET'])
@jwt_required()
def get_user():
    try:
        current_user_id = get_jwt_identity()
        user_response = supabase.table('users').select('id', 'username', 'email', 'points').eq('id', current_user_id).execute()

        if not user_response.data or len(user_response.data) == 0:
            return jsonify({'error': 'Utente non trovato.'}), 404

        user = user_response.data[0]
        return jsonify({'user': user}), 200
    except Exception as e:
        logger.error(f"Errore nel recupero dell'utente: {e}")
        return jsonify({'error': 'Errore interno del server.'}), 500

# Endpoint per recuperare la lista delle lobby (HTTP fallback)
@app.route('/lobbies', methods=['GET'])
@jwt_required()
def get_lobbies_http():
    try:
        return jsonify({'lobbies': list(lobbies.values())}), 200
    except Exception as e:
        logger.error(f"Errore nel recupero delle lobby: {e}")
        return jsonify({'error': 'Errore interno del server.'}), 500

# Funzione per inviare la lista delle lobby a tutti i client
def broadcast_lobbies():
    socketio.emit('update_lobbies', {'lobbies': list(lobbies.values())}, broadcast=True)

# Esegui l'app Flask con SocketIO
if __name__ == '__main__':
    logger.info("Avvio del server Flask con SocketIO...")
    socketio.run(app, host='0.0.0.0', port=5001)