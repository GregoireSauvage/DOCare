import 'dart:html';
import 'package:docare/user.dart';
import 'package:docare/document.dart';
import 'package:provider/provider.dart';

class Demarche {

  int id;
  String name;
  String description;
  List<String> documentsNecessaires; // liste des documents nécessaires de la démarche
  List<Document> documentsFournis; // liste des documents fournis par l'utilisateur

  Demarche({
    required this.id,
    required this.name,
    required this.description,
    required this.documentsNecessaires,
    required this.documentsFournis,
  });


}