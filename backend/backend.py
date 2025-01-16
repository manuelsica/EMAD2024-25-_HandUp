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
import bcrypt
from flask_jwt_extended import (
    JWTManager, create_access_token, decode_token, get_jwt_identity, jwt_required
)
from flask_socketio import SocketIO, emit, join_room, leave_room, disconnect
from datetime import timedelta
import uuid
import json

# Configurazioni di base
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# Configurazione JWT
app.config['JWT_SECRET_KEY'] = 'V^8pZ4!kF#2sX@uJ9$L1mB&dR5eT3yC8oQ'
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(days=7)
jwt = JWTManager(app)

# Configura Supabase
SUPABASE_URL = "https://nrgzyxhkkuselsgbfzcq.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5yZ3p5eGhra3VzZWxzZ2JmemNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU5NDQ5MzIsImV4cCI6MjA1MTUyMDkzMn0.eX64nn7VpFqiPohWTRG_jk2sOPpsPMoKWxop5DN53-o"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Configura Generative AI
genai.configure(api_key="")  # Sostituisci con la tua chiave API
generative_model = genai.GenerativeModel("gemini-1.5-flash")
logger.info("Modello GenerativeModel di Gemini caricato con successo.")

# Carica modello Keras (.h5)
model_path = 'model_ufficial.h5'
try:
    model = load_model(model_path)
    logger.info("Modello Keras (.h5) caricato con successo.")
except Exception as e:
    logger.error(f"Errore caricamento modello Keras: {e}")
    sys.exit()

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=2, min_detection_confidence=0.5)

labels_dict = {i: chr(65 + i) for i in range(26)}

socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

# Dizionario per mappare sid a user_id
users = {}

def get_all_lobbies_from_db():
    """Recupera le lobby da view_lobbies e i relativi giocatori da lobby_players."""
    try:
        resp_lobbies = supabase.table("view_lobbies").select("*").execute()
        lobbies_data = resp_lobbies.data

        # Recupera anche is_ready e user_id
        resp_players = supabase.table("lobby_players") \
            .select("lobby_id, user_id, is_ready, users(username)") \
            .execute()
        players_data = resp_players.data

        lobby_players_map = {}
        for row in players_data:
            lid = row["lobby_id"]
            username = row["users"]["username"]
            user_id = row["user_id"]
            is_ready = row["is_ready"]

            if lid not in lobby_players_map:
                lobby_players_map[lid] = []

            lobby_players_map[lid].append({
                "user_id": user_id,
                "username": username,
                "is_ready": is_ready
            })

        final_list = []
        for lb in lobbies_data:
            lb_id = lb["id"]
            final_list.append({
                "id": lb["id"],
                "lobby_id": lb["lobby_id"],
                "lobby_name": lb["lobby_name"],
                "type": lb["type"],
                "num_players": lb["num_players"],
                "current_players": lb["current_players"],
                "creator": lb["creator_id"],
                "is_locked": lb["is_locked"],
                "players": lobby_players_map.get(lb_id, [])
            })
        return final_list
    except Exception as e:
        logger.error(f"Errore nel recupero delle lobby: {e}")
        return []

def broadcast_lobbies():
    """Manda la lista aggiornata a tutti i client."""
    all_lobbies = get_all_lobbies_from_db()
    socketio.emit('update_lobbies', {'lobbies': all_lobbies})

def generate_lobby_id(length=6):
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))

#################### SOCKET.IO EVENTS ####################

@socketio.on('connect')
def handle_connect():
    token = request.args.get('token')
    if not token:
        emit('error', {'error': 'Token mancante.'})
        disconnect()
        return

    try:
        decoded_token = decode_token(token)
        user_id = decoded_token['sub']
        if not user_id:
            emit('error', {'error': 'Token non valido.'})
            disconnect()
            return

        # Associa l'user_id al sid
        users[request.sid] = user_id
        logger.info(f"Utente {user_id} connesso a SocketIO con sid {request.sid}.")
        emit('connected', {'message': 'Connesso al server SocketIO.'})

    except Exception as e:
        logger.error(f"Errore nella decodifica del token: {e}")
        emit('error', {'error': 'Token non valido.'})
        disconnect()

@socketio.on('disconnect')
def handle_disconnect():
    user_id = users.get(request.sid, 'Unknown')
    logger.info(f"Utente {user_id} disconnesso da SocketIO con sid {request.sid}.")
    users.pop(request.sid, None)

def get_current_user_id():
    """Recupera l'ID utente associato al socket corrente."""
    return users.get(request.sid)

@socketio.on('create_lobby')
def handle_create_lobby(data):
    try:
        current_user_id = get_current_user_id()
        if not current_user_id:
            emit('error', {'error': 'Utente non autenticato.'})
            return

        logger.info(f"create_lobby ricevuto: {data}")

        lobby_name = data.get('lobby_name')
        lobby_type = data.get('type')
        num_players = data.get('num_players')
        password = data.get('password', None)

        if not lobby_name or not lobby_type or not num_players:
            emit('error', {'error': 'Campi mancanti per la creazione della lobby.'})
            logger.warning("Creazione lobby fallita: campi mancanti.")
            return

        logger.info(f"Creazione lobby con nome: {lobby_name}, tipo: {lobby_type}, numero giocatori: {num_players}")

        # Recupera username
        user_resp = supabase.table('users').select('id, username').eq('id', current_user_id).execute()
        if not user_resp.data:
            emit('error', {'error': 'Utente non trovato.'})
            logger.warning(f"Utente con ID {current_user_id} non trovato durante la creazione della lobby.")
            return
        creator_username = user_resp.data[0]['username']

        lobby_id_text = generate_lobby_id()
        logger.info(f"Generated lobby_id: {lobby_id_text}")

        new_lobby = supabase.table('lobbies').insert({
            'lobby_id': lobby_id_text,
            'creator_id': current_user_id,
            'lobby_name': lobby_name,
            'type': lobby_type,
            'num_players': num_players,
            'password': password
        }).execute()

        if not new_lobby.data:
            emit('error', {'error': 'Impossibile creare la lobby.'})
            logger.error("Errore durante l'inserimento della lobby nel DB.")
            return

        created_lobby = new_lobby.data[0]
        logger.info(f"Lobby creata: {created_lobby}")

        supabase.table('lobby_players').insert({
            'lobby_id': created_lobby['id'],
            'user_id': current_user_id
        }).execute()
        logger.info(f"Utente {current_user_id} aggiunto a 'lobby_players' per la lobby {created_lobby['id']}.")

        join_room(created_lobby['lobby_id'])
        logger.info(f"Utente {current_user_id} unito alla stanza '{created_lobby['lobby_id']}'.")

        emit('lobby_created', {
            'lobby': {
                'id': created_lobby['id'],
                'lobby_id': created_lobby['lobby_id'],
                'lobby_name': created_lobby['lobby_name'],
                'type': created_lobby['type'],
                'num_players': created_lobby['num_players'],
                'current_players': 1,
                'creator': creator_username,
                'is_locked': bool(password),
                'players': [{
                    'user_id': current_user_id,
                    'username': creator_username,
                    'is_ready': False
                }]
            }
        }, room=request.sid)
        logger.info(f"Lobby {created_lobby['lobby_id']} creata e giocatore aggiunto.")

        broadcast_lobbies()
        logger.info("Broadcast delle lobby aggiornata.")

    except Exception as e:
        logger.error(f"Eccezione in create_lobby: {e}")
        emit('error', {'error': 'Errore nella creazione della lobby.'})

@socketio.on('join_lobby')
def handle_join_lobby(data):
    try:
        current_user_id = get_current_user_id()
        if not current_user_id:
            emit('error', {'error': 'Utente non autenticato.'})
            return

        lobby_id_text = data.get('lobby_id')
        input_password = data.get('password', None)

        if not lobby_id_text:
            emit('error', {'error': 'ID della lobby mancante.'})
            return

        # Recupera la lobby
        lobby_resp = supabase.table('lobbies') \
            .select('id, lobby_id, password, num_players') \
            .eq('lobby_id', lobby_id_text) \
            .execute()
        if not lobby_resp.data:
            emit('error', {'error': 'Lobby non trovata.'})
            return
        db_lobby = lobby_resp.data[0]

        count_resp = supabase.table('lobby_players') \
            .select('user_id', count='exact') \
            .eq('lobby_id', db_lobby['id']) \
            .execute()
        current_players_count = count_resp.count or 0

        if current_players_count >= db_lobby['num_players']:
            emit('error', {'error': 'Lobby piena.'})
            return

        if db_lobby['password']:
            if not input_password or input_password != db_lobby['password']:
                emit('error', {'error': 'Password della lobby errata.'})
                return

        supabase.table('lobby_players').insert({
            'lobby_id': db_lobby['id'],
            'user_id': current_user_id
        }).execute()

        join_room(db_lobby['lobby_id'])

        emit('joined_lobby', {'lobby_id': db_lobby['lobby_id']}, room=request.sid)
        socketio.emit('player_joined', {'user_id': current_user_id}, to=db_lobby['lobby_id'])

        broadcast_lobbies()

    except Exception as e:
        logger.error(f"Errore nell'unirsi alla lobby: {e}")
        emit('error', {'error': 'Errore nell\'unirsi alla lobby.'})

@socketio.on('leave_lobby')
def handle_leave_lobby(data):
    """
    Rimuove l'utente dalla lobby.
    Se la lobby diventa vuota, la elimina.
    Se l'owner esce ma rimangono altri player, ownership passa casualmente a un altro.
    """
    try:
        current_user_id = get_current_user_id()
        if not current_user_id:
            emit('error', {'error': 'Utente non autenticato.'})
            return

        lobby_id_text = data.get('lobby_id')

        if not lobby_id_text:
            emit('error', {'error': 'Lobby non valida.'})
            return

        # Recupera la lobby
        resp = supabase.table('lobbies').select('id, lobby_id, creator_id').eq('lobby_id', lobby_id_text).execute()
        if not resp.data:
            emit('error', {'error': 'Lobby non trovata.'})
            return
        db_lobby = resp.data[0]

        # Rimuove l'utente da lobby_players
        supabase.table('lobby_players') \
            .delete() \
            .eq('lobby_id', db_lobby['id']) \
            .eq('user_id', current_user_id) \
            .execute()

        leave_room(db_lobby['lobby_id'])

        # Conta i player rimanenti
        count_p = supabase.table('lobby_players') \
            .select('user_id', count='exact') \
            .eq('lobby_id', db_lobby['id']) \
            .execute()
        curr_count = count_p.count or 0

        if curr_count == 0:
            # Lobby vuota -> Elimina
            supabase.table('lobbies') \
                .delete() \
                .eq('id', db_lobby['id']) \
                .execute()
            socketio.emit('lobby_closed', {'lobby_id': db_lobby['lobby_id']})
            logger.info(f"Lobby {db_lobby['lobby_id']} chiusa (vuota).")
        else:
            # Se non è vuota, verifica se il leaver era il creator
            existing_lobby_resp = supabase.table('lobbies') \
                .select('creator_id') \
                .eq('id', db_lobby['id']) \
                .execute()
            if existing_lobby_resp.data:
                existing_lobby = existing_lobby_resp.data[0]
                if existing_lobby['creator_id'] == current_user_id:
                    # L’owner era l’utente che sta lasciando => passiamo la ownership
                    players_resp = supabase.table('lobby_players') \
                        .select('user_id') \
                        .eq('lobby_id', db_lobby['id']) \
                        .execute()
                    if players_resp.data:
                        from random import choice
                        # Scegli casualmente un nuovo owner
                        new_owner_id = choice([p['user_id'] for p in players_resp.data])
                        supabase.table('lobbies') \
                            .update({'creator_id': new_owner_id}) \
                            .eq('id', db_lobby['id']) \
                            .execute()
                        logger.info(f"Nuovo owner (random): {new_owner_id} per la lobby {db_lobby['lobby_id']}.")
            # Notifica a tutti i player rimasti
            socketio.emit('player_left', {'user_id': current_user_id}, to=db_lobby['lobby_id'])

        # Broadcast
        broadcast_lobbies()

        logger.info(f"Utente {current_user_id} ha lasciato la lobby {db_lobby['lobby_id']}.")
    except Exception as e:
        logger.error(f"Errore nel leave_lobby: {e}")
        emit('error', {'error': 'Errore nel lasciare la lobby.'})

@socketio.on('start_game')
def handle_start_game(data):
    try:
        current_user_id = get_current_user_id()
        if not current_user_id:
            emit('error', {'error': 'Utente non autenticato.'})
            return

        lobby_id_text = data.get('lobby_id')

        if not lobby_id_text:
            emit('error', {'error': 'Lobby non valida.'})
            return

        resp = supabase.table('lobbies') \
            .select('id, lobby_id, creator_id') \
            .eq('lobby_id', lobby_id_text) \
            .execute()
        if not resp.data:
            emit('error', {'error': 'Lobby non trovata.'})
            return
        db_lobby = resp.data[0]

        if db_lobby['creator_id'] != current_user_id:
            emit('error', {'error': 'Solo il creatore può avviare il gioco.'})
            return

        # Emettiamo l'evento 'game_started' a tutti nella lobby
        socketio.emit(
            'game_started',
            {'lobby_id': db_lobby['lobby_id']},
            to=db_lobby['lobby_id']
        )

    except Exception as e:
        logger.error(f"Errore start_game: {e}")
        emit('error', {'error': 'Errore nell\'avviare il gioco.'})

@socketio.on('toggle_ready')
def handle_toggle_ready(data):
    try:
        current_user_id = get_current_user_id()
        if not current_user_id:
            emit('error', {'error': 'Utente non autenticato.'})
            return

        lobby_id_text = data.get('lobby_id')

        # Recupera la lobby
        resp = supabase.table('lobbies').select('id').eq('lobby_id', lobby_id_text).execute()
        if not resp.data:
            emit('error', {'error': 'Lobby non trovata.'})
            return
        db_lobby_id = resp.data[0]['id']

        # Aggiorna lo stato "is_ready" per l’utente in lobby_players
        new_ready_state = data.get('is_ready', False)
        supabase.table('lobby_players') \
                .update({'is_ready': new_ready_state}) \
                .eq('lobby_id', db_lobby_id) \
                .eq('user_id', current_user_id) \
                .execute()

        # Avvisa tutti della lobby aggiornata
        broadcast_lobbies()
    except Exception as e:
        logger.error(f"Errore toggle_ready: {e}")
        emit('error', {'error': 'Errore nel cambiare stato pronto.'})

@socketio.on('vote_mode')
def handle_vote_mode(data):
    """
    data: { "lobby_id": "...", "mode": "facile|medio|difficile" }
    """
    try:
        current_user_id = get_current_user_id()
        if not current_user_id:
            emit('error', {'error': 'Utente non autenticato.'})
            return

        lobby_id_text = data.get('lobby_id')
        chosen_mode = data.get('mode')

        if not lobby_id_text or not chosen_mode:
            emit('error', {'error': 'Parametri mancanti per la votazione.'})
            return

        # Recupera la lobby dal DB
        resp = supabase.table('lobbies').select('id').eq('lobby_id', lobby_id_text).execute()
        if not resp.data:
            emit('error', {'error': 'Lobby non trovata.'})
            return
        db_lobby = resp.data[0]
        db_lobby_id = db_lobby["id"]

        # Inizializza se non esiste in memory
        if lobby_id_text not in lobby_votes:
            lobby_votes[lobby_id_text] = {
                "numPlayers": get_number_of_players(db_lobby_id),
                "votes": {}
            }

        # Salva la scelta
        lobby_votes[lobby_id_text]["votes"][current_user_id] = chosen_mode
        logging.info(f"Voto: utente={current_user_id}, lobby={lobby_id_text}, mode={chosen_mode}")

        # Calcola i conteggi dei voti attuali
        votes_dict = lobby_votes[lobby_id_text]["votes"]
        vote_counts = {"facile": 0, "medio": 0, "difficile": 0}
        for vote in votes_dict.values():
            if vote in vote_counts:
                vote_counts[vote] += 1

        # Emissione aggiornamento voti a tutti i client nella lobby
        socketio.emit(
            'vote_update',
            {"vote_counts": vote_counts},
            to=lobby_id_text
        )
        logging.info(f"Aggiornamento voti inviato per la lobby {lobby_id_text}: {vote_counts}")

        # Se TUTTI i player di questa lobby hanno votato:
        total_players = lobby_votes[lobby_id_text]["numPlayers"]
        if len(votes_dict) == total_players and total_players > 0:
            # Calcola la modalità vincente
            # Conta i voti: { "facile": n, "medio": n, "difficile": n }
            counter = {}
            for m in votes_dict.values():
                counter[m] = counter.get(m, 0) + 1

            # Trova max
            max_count = max(counter.values())
            # Prendi tutte le modalità che hanno max_count
            candidates = [mode for mode, cnt in counter.items() if cnt == max_count]

            if len(candidates) == 1:
                final_mode = candidates[0]
            else:
                final_mode = random.choice(candidates)  # spareggio casuale

            logging.info(f"Risultato votazione (lobby={lobby_id_text}): {final_mode}")

            # Emissione a tutti
            broadcast_vote_result(lobby_id_text, final_mode)

            # Reset voti (opzionale, se vuoi che dopo la partita possano rivotare)
            lobby_votes.pop(lobby_id_text, None)

    except Exception as e:
        logging.error(f"Errore in vote_mode: {e}")
        emit('error', {'error': 'Errore interno in vote_mode.'})

# ======== STRUTTURA DATI PER LE VOTAZIONI IN MEMORIA =========
lobby_votes = {}
# Formato: {
#   lobby_id (string): {
#       "numPlayers": 2 (numero TOT di player in lobby),
#       "votes": {
#           user_id (uuid/str): "facile"|"medio"|"difficile"
#       }
#   }
# }

# Funzione d'appoggio per recuperare num. player della lobby
def get_number_of_players(lobby_uuid):
    """
    Ritorna quanti giocatori risultano in lobby_players per la lobby 'lobby_uuid'
    """
    resp = supabase.table("lobby_players").select("user_id", count='exact').eq("lobby_id", lobby_uuid).execute()
    return resp.count if resp.count else 0

# Emissione risultato
def broadcast_vote_result(lobby_id, mode_chosen):
    # Manda a tutti i client nella room = lobby_id
    socketio.emit(
        'vote_result',
        {"mode_chosen": mode_chosen},
        to=lobby_id
    )

# Emissione evento 'start_timer' quando tutti i giocatori sono pronti
player_screen_map = {}
# struttura: { "LOBBY_ID": set([user1, user2, ...]) }

@socketio.on('player_on_game_screen')
def handle_player_on_game_screen(data):
    try:
        current_user_id = get_current_user_id()
        if not current_user_id:
            emit('error', {'error': 'Utente non autenticato.'})
            return

        lobby_id_text = data.get('lobby_id')
        if not lobby_id_text:
            emit('error', {'error': 'Lobby non valida.'})
            logger.warning("Evento 'player_on_game_screen' ricevuto senza 'lobby_id'.")
            return

        logger.info(f"Gestione 'player_on_game_screen' per lobby_id: {lobby_id_text} da utente: {current_user_id}")

        # Recupera la lobby dal DB
        resp = supabase.table('lobbies').select('id').eq('lobby_id', lobby_id_text).execute()
        if not resp.data:
            emit('error', {'error': 'Lobby non trovata.'})
            logger.warning(f"Lobby con lobby_id: {lobby_id_text} non trovata.")
            return
        db_lobby = resp.data[0]
        db_lobby_id = db_lobby["id"]
        logger.info(f"Lobby trovata: ID Interno = {db_lobby_id}")

        # Conteggio totale player
        resp_count = supabase.table('lobby_players') \
            .select('user_id', count='exact') \
            .eq('lobby_id', db_lobby_id).execute()
        total_players_in_lobby = resp_count.count or 0
        logger.info(f"Numero totale di giocatori nella lobby '{lobby_id_text}': {total_players_in_lobby}")

        # Aggiorna la mappa dei giocatori nella GameScreen
        if lobby_id_text not in player_screen_map:
            player_screen_map[lobby_id_text] = set()
            logger.info(f"Inizializzata nuova entry in player_screen_map per lobby_id: {lobby_id_text}")

        # Aggiungi l'utente corrente
        if current_user_id in player_screen_map[lobby_id_text]:
            logger.info(f"Utente {current_user_id} ha già segnalato di essere nella GameScreen per la lobby '{lobby_id_text}'.")
        else:
            player_screen_map[lobby_id_text].add(current_user_id)
            logger.info(f"Utente {current_user_id} aggiunto a player_screen_map per la lobby '{lobby_id_text}'.")
            logger.info(f"Numero di giocatori segnati nella GameScreen: {len(player_screen_map[lobby_id_text])}")

        # Verifica se tutti i giocatori sono nella GameScreen
        if len(player_screen_map[lobby_id_text]) == total_players_in_lobby:
            logger.info(f"Tutti i giocatori sono presenti nella GameScreen per la lobby '{lobby_id_text}'. Emissione di 'start_timer'.")
            socketio.emit(
                'start_timer',
                {'message': 'Tutti i player presenti, avvio timer!'},
                to=lobby_id_text
            )
            # Reset della mappa per future partite
            player_screen_map.pop(lobby_id_text, None)
        else:
            logger.info(f"Mancano {total_players_in_lobby - len(player_screen_map[lobby_id_text])} giocatori per avviare il timer nella lobby '{lobby_id_text}'.")

    except Exception as e:
        logger.error(f"Errore in player_on_game_screen: {e}")
        emit('error', {'error': 'Errore nel segnalare player_on_game_screen.'})

#################### ENDPOINTS HTTP DI SERVIZIO ####################

@app.route('/lobbies', methods=['GET'])
@jwt_required()
def get_lobbies_http():
    try:
        data = get_all_lobbies_from_db()
        return jsonify({'lobbies': data}), 200
    except Exception as e:
        logger.error(f"Errore /lobbies GET: {e}")
        return jsonify({'error': 'Errore interno del server.'}), 500

def correct_image_orientation(image_data, platform):
    try:
        img_pil = Image.open(io.BytesIO(image_data))
        exif = img_pil._getexif()
        orientation_key = None
        for k, v in ExifTags.TAGS.items():
            if v == 'Orientation':
                orientation_key = k
                break

        if exif and orientation_key in exif:
            orientation_val = exif[orientation_key]
            if orientation_val == 3:
                img_pil = img_pil.rotate(180, expand=True)
            elif orientation_val == 6:
                img_pil = img_pil.rotate(270, expand=True)
            elif orientation_val == 8:
                img_pil = img_pil.rotate(90, expand=True)

        if platform == 'android':
            w, h = img_pil.size
            if w > h:
                img_pil = img_pil.rotate(90, expand=True)

        return np.array(img_pil)
    except Exception as e:
        logger.error(f"Errore orientamento immagine: {e}")
        return None

@app.route('/predict/', methods=['POST'])
@jwt_required()
def predict():
    try:
        data = request.get_json()
        if 'image' not in data or 'platform' not in data:
            return jsonify({'error': "Missing 'image' or 'platform'."}), 400

        platform = data['platform']
        image_data = base64.b64decode(data['image'])
        cimg = correct_image_orientation(image_data, platform)
        if cimg is None:
            return jsonify({'error': "Impossibile correggere l'orientamento."}), 400

        frame = cv2.cvtColor(cimg, cv2.COLOR_RGB2BGR)
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = hands.process(frame_rgb)

        predictions = []
        if results.multi_hand_landmarks:
            for idx, hlm in enumerate(results.multi_hand_landmarks):
                data_aux = []
                x_ = [lm.x for lm in hlm.landmark]
                y_ = [lm.y for lm in hlm.landmark]
                min_x, min_y = min(x_), min(y_)

                for lm in hlm.landmark:
                    data_aux.append(lm.x - min_x)
                    data_aux.append(lm.y - min_y)

                input_length = model.input_shape[1]
                if len(data_aux) < input_length:
                    data_aux += [0]*(input_length - len(data_aux))
                else:
                    data_aux = data_aux[:input_length]

                prediction = model.predict(np.array(data_aux).reshape(1, input_length))
                pred_index = np.argmax(prediction)
                confidence = float(np.max(prediction))*100
                predicted_character = labels_dict.get(pred_index, '')

                hand_type = ("Right Hand"
                             if results.multi_handedness[idx].classification[0].label == "Right"
                             else "Left Hand")
                predictions.append({
                    'hand': idx+1,
                    'hand_type': hand_type,
                    'character': predicted_character,
                    'confidence': confidence
                })

        return jsonify({'predictions': predictions}), 200
    except Exception as e:
        logger.error(f"Errore predict: {e}")
        return jsonify({'error': str(e)}), 500

def genera_parole(modalita):
    if modalita == "facile":
        lmin, lmax = 3, 5
    elif modalita == "medio":
        lmin, lmax = 6, 8
    elif modalita == "difficile":
        lmin, lmax = 8, 20
    else:
        return []

    prompt = (
        f"Genera una lista di 10 parole uniche e significative. "
        f"Le parole devono avere una lunghezza compresa tra {lmin} e {lmax} caratteri. "
        f"Le parole non devono contenere accenti (come à, è, ò, ù) o caratteri speciali come simboli o numeri. "
        f"Rispondi in formato lista numerata con parole di senso compiuto e che esistono."
    )
    logger.info(f"Prompt generato: {prompt}")
    try:
        response = generative_model.generate_content(prompt)
        pattern = r"^\d+\.\s*(\w+)"
        matches = re.findall(pattern, response.text, re.MULTILINE)
        parole_filtrate = [p for p in matches if lmin <= len(p) <= lmax]
        return parole_filtrate[:10]
    except Exception as e:
        logger.error(f"Errore generazione parole: {e}")
        return []

@app.route('/generate-words', methods=['POST'])
@jwt_required()
def generate_words():
    try:
        data = request.get_json()
        modalita = data.get("modalita")
        if modalita not in ["facile", "medio", "difficile"]:
            return jsonify({"error": "Modalità non valida"}), 400

        words = genera_parole(modalita)
        return jsonify({"words": words}), 200
    except Exception as e:
        logger.error(f"Errore generate_words: {e}")
        return jsonify({"error": str(e)}), 500

#################### ENDPOINTS AUTENTICAZIONE ####################

@app.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        confirm_password = data.get('confirm_password')

        if not username or not email or not password or not confirm_password:
            return jsonify({'error': 'Tutti i campi sono obbligatori.'}), 400

        if password != confirm_password:
            return jsonify({'error': 'Le password non corrispondono.'}), 400

        email_regex = r"[^@]+@[^@]+\.[^@]+"
        if not re.match(email_regex, email):
            return jsonify({'error': 'Email non valida.'}), 400

        existing_user = supabase.table('users').select('id').eq('email', email).execute()
        if existing_user.data and len(existing_user.data) > 0:
            return jsonify({'error': 'Email già registrata.'}), 400

        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        new_user = supabase.table('users').insert({
            'username': username,
            'email': email,
            'password': hashed_password,
            'points': 0
        }).execute()

        if new_user.data and len(new_user.data) > 0:
            user_id = new_user.data[0].get('id')
            access_token = create_access_token(identity=user_id)
            username_res = new_user.data[0].get('username')
            points = new_user.data[0].get('points', 0)

            return jsonify({
                'message': 'Registrazione avvenuta con successo.',
                'access_token': access_token,
                'username': username_res,
                'points': points,
                'user_id': user_id
            }), 201

        logger.error("Errore durante l'inserimento dell'utente.")
        return jsonify({'error': 'Errore durante la registrazione.'}), 500

    except Exception as e:
        logger.error(f"Errore nella registrazione: {e}")
        return jsonify({'error': 'Errore interno del server.'}), 500

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({'error': 'Email e password sono obbligatorie.'}), 400

        email_regex = r"[^@]+@[^@]+\.[^@]+"
        if not re.match(email_regex, email):
            return jsonify({'error': 'Email non valida.'}), 400

        user_response = supabase.table('users').select('*').eq('email', email).execute()
        logger.info(f"Risposta Supabase (login): {user_response}")

        if not user_response.data or len(user_response.data) == 0:
            return jsonify({'error': 'Email o password errate.'}), 401

        user = user_response.data[0]
        stored_hashed_password = user.get('password')
        if not stored_hashed_password:
            logger.error("Password non trovata per l'utente.")
            return jsonify({'error': 'Errore durante il login.'}), 500

        if not bcrypt.checkpw(password.encode('utf-8'), stored_hashed_password.encode('utf-8')):
            return jsonify({'error': 'Email o password errate.'}), 401

        access_token = create_access_token(identity=user['id'])
        username = user.get('username', 'Username')
        points = user.get('points', 0)

        return jsonify({
            'message': 'Login effettuato con successo.',
            'access_token': access_token,
            'username': username,
            'points': points,
            'user_id': user['id']
        }), 200

    except Exception as e:
        logger.error(f"Errore nel login: {e}")
        return jsonify({'error': 'Errore interno del server.'}), 500

@app.route('/user', methods=['GET'])
@jwt_required()
def get_user():
    try:
        current_user_id = get_jwt_identity()
        user_response = supabase.table('users')\
            .select('id, username, email, points')\
            .eq('id', current_user_id).execute()

        if not user_response.data or len(user_response.data) == 0:
            return jsonify({'error': 'Utente non trovato.'}), 404

        user = user_response.data[0]
        return jsonify({'user': user}), 200
    except Exception as e:
        logger.error(f"Errore get_user: {e}")
        return jsonify({'error': 'Errore interno del server.'}), 500


@app.route('/leaderboard', methods=['GET'])
@jwt_required()
def get_leaderboard():
    try:
        current_user_id = get_jwt_identity()
        logger.info(f"Recupero della classifica per l'utente ID: {current_user_id}")

        # Recupera tutti gli utenti ordinati per punti decrescenti
        response = supabase.table('users').select('id, username, points').order('points', desc=True).execute()

        # Log della risposta per debug
        logger.debug(f"Response data: {response.data}")

        # Verifica se la risposta contiene dati
        if response.data is None:
            logger.error("La risposta di Supabase non contiene dati.")
            return jsonify({'error': 'Errore nel recupero leaderboard.'}), 500

        users = response.data  # Lista di dizionari con 'id', 'username', 'points'

        leaderboard = []
        your_rank = None
        your_points = None

        for index, user in enumerate(users, start=1):
            leaderboard.append({
                'username': user['username'],
                'points': user['points']
            })
            if user['id'] == current_user_id:
                your_rank = index
                your_points = user['points']

        logger.info(f"Classifica recuperata con successo. Rango utente: {your_rank}")

        return jsonify({
            'leaderboard': leaderboard,
            'your_rank': your_rank,
            'your_points': your_points
        }), 200

    except Exception as e:
        logger.error(f"Errore in get_leaderboard: {e}")
        return jsonify({'error': 'Errore interno del server.'}), 500
def reset_server_state():
    """Elimina tutte le lobby e disconnette tutti gli utenti all'avvio del server."""
    try:
        # Elimina tutte le lobby dove 'lobby_id' non è vuoto
        response_lobbies = supabase.table('lobbies').delete().neq('lobby_id', '').execute()

        # Verifica se l'eliminazione delle lobby è andata a buon fine
        if response_lobbies.status_code == 200:
            logger.info("Tutte le lobby sono state eliminate.")
        else:
            logger.error(f"Errore nell'eliminazione di 'lobbies': {response_lobbies.json()}")

        # Non è necessario eliminare 'lobby_players' manualmente grazie a 'ON DELETE CASCADE'

        # Emissione evento di disconnessione a tutti i client
        socketio.emit('force_disconnect', {'message': 'Server riavviato. Sei stato disconnesso.'})
        logger.info("Tutti gli utenti sono stati disconnessi.")
    except AttributeError as ae:
        # Gestione specifica per AttributeError
        logger.error(f"Errore attributo nella risposta Supabase: {ae}")
    except Exception as e:
        logger.error(f"Errore nel reset dello stato del server: {e}")


if __name__ == '__main__':
    logger.info("Reset dello stato del server in corso...")
    reset_server_state()  # Ripulisce le lobby e disconnette gli utenti all'avvio

    logger.info("Avvio del server Flask con SocketIO...")
    socketio.run(app, host='0.0.0.0', port=5001)