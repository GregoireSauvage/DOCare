from flask import Flask, request, jsonify
import tensorflow as tf
import os


app = Flask(__name__)

# Chargement du modèle SavedModel
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

    # Utilisation du modèle chargé
    result = loaded_model.predict(new_image_array)
    class_names = {0: 'Papier_administratif', 1: 'imagerie_medicale', 2: 'papier_identite'}
    predicted_class = tf.argmax(result[0]).numpy()
    predicted_class_name = class_names[predicted_class]

    # Supprimer l'image temporaire
    os.remove(image_path)

    return jsonify({'predicted_class': predicted_class_name})

if __name__ == '__main__':
    app.run(debug=False)