import 'package:docare/document.dart';
import 'package:flutter/material.dart';

class Demarche extends ChangeNotifier {

  int id;
  String name;
  String description;
  String lien; // lien vers la page de la démarche
  List<String> documentsNecessaires; // liste des documents nécessaires de la démarche
  List<String> tagsDocumentsNecessaires; // liste des tags des documents nécessaires
  List<Document> documentsFournis; // liste des documents fournis par l'utilisateur

  Demarche({
    required this.id,
    required this.name,
    required this.description,
    required this.lien,
    required this.documentsNecessaires,
    required this.tagsDocumentsNecessaires,
    required this.documentsFournis,
  });

  void addDocument(Document document) {
    documentsFournis.add(document);
    notifyListeners(); // Notifies all the listening widgets to rebuild.
  }

}