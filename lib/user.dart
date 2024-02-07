import 'package:docare/document.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'
    show ChangeNotifier, ChangeNotifierProvider;
import 'package:docare/folder.dart';
import 'package:collection/collection.dart';

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

  void removeFolder(int folderId) {

    Folder? folderToRemove = folderList.firstWhereOrNull((folder) => folder.id == folderId);
    // Remove the folder from the list
    if(folderToRemove != null){
      folderList.remove(folderToRemove);
    }

    // Notify listeners to rebuild widgets that depend on the folderList
    notifyListeners();
  }


  void removeDocument(Document document) {
    for (Folder folder in folderList) {
      if (folder.folders.contains(document)) {
        folder.removeFile(document);
        break;
      }
    }
    notifyListeners(); // If User extends ChangeNotifier
  }
}
