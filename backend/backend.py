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

# Configura il logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configurazione Flask
app = Flask(__name__)
CORS(app)

# Configura la chiave API per Gemini e carica il modello generativo
genai.configure(api_key="CHIAVE")
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

# Endpoint per predire la lettera dalla foto
@app.route('/predict/', methods=['POST'])
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

# Esegui l'app Flask
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
