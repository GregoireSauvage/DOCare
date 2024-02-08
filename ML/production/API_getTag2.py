from flask import Flask, request, jsonify
import tensorflow as tf
import joblib
import numpy as np
from PIL import Image
from skimage import transform
import os
import tensorflow
import keras_ocr

app = Flask(__name__)

# Chargement du modèle principal
loaded_model = tf.keras.models.load_model('D:/projet/DOCare/DOCare/ML/production/Model_cat_etape1')
img_size = (128, 128)

@app.route('/predict', methods=['POST'])
def predict():
    print("Received a request")
    # Récupérer l'image depuis la requête POST
    image_file = request.files['image']
    image_path = 'temp_image.jpg'
    image_file.save(image_path)

    # Prétraitement de l'image
    new_image = tf.keras.preprocessing.image.load_img(image_path, target_size=img_size)
    new_image_array = tf.keras.preprocessing.image.img_to_array(new_image)
    new_image_array = tf.expand_dims(new_image_array, 0)

    # Utilisation du modèle principal pour prédire la classe principale
    result = loaded_model.predict(new_image_array)
    class_names = {0: 'PapierA4', 1: 'imagerie_medicale', 2: 'papier_identite'}
    predicted_class = tf.argmax(result[0]).numpy()
    predicted_class_name = class_names[predicted_class]

    # Utilisation du modèle correspondant à la classe principale prédite pour prédire la sous-catégorie
    if predicted_class_name == "papier_identite":
        model = joblib.load('D:/projet/DOCare/DOCare/ML/production/model_papierid.pkl')
    elif predicted_class_name == "PapierA4":
        model = joblib.load('D:/projet/DOCare/DOCare/ML/production/model_papierA4.pkl')
    else:
        return jsonify({'predicted_class': 'Imagerie médicale'})

    # Prédiction de la sous-catégorie
    pipeline = keras_ocr.pipeline.Pipeline()
    images = [keras_ocr.tools.read(image_path)]
    prediction_groups = pipeline.recognize(images)
    texts = [' '.join([text for text, _ in predicted_image]) for predicted_image in prediction_groups]
    subcategory_prediction = model.predict(texts)

    # Supprimer l'image temporaire
    os.remove(image_path)

    print('subcategory_prediction', subcategory_prediction)
    return jsonify({'predicted_class': predicted_class_name, 'subcategory_prediction': subcategory_prediction.tolist()})

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=False)
    