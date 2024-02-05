import 'package:docare/document.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'
    show ChangeNotifier, ChangeNotifierProvider;
import 'package:docare/folder.dart';

class User extends ChangeNotifier {
  int userId;
  String username;
  String email;
  String passwordHash;
  List<Folder> folderList; // liste des dossiers de l'utilisateur

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.folderList,
  });

  void addFolder(Folder folder) {
    folderList.add(folder);
    notifyListeners(); // If User extends ChangeNotifier
  }
}
