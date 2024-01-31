import 'package:docare/folder.dart';
import 'file_system_entity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docare/user.dart';

class Document extends FileSystemEntity {
  int id;
  String title;
  String fileType;
  String path;  // chemin du fichier
  DateTime creationDate;
  int ownerId; // id de l'utilisateur propriétaire du document
  Folder folder; // id du dossier dans lequel se trouve le document

  Document({
    required this.id,
    required this.title,
    required this.fileType,
    required this.path,
    required this.creationDate,
    required this.ownerId,
    required this.folder,
  
  }) : super(name: title, type: false) {
    folder.addFile(this); // Ajout du document au dossier
  }

  // Getters
  int getId() {return id;}
  String getTitle() {return title;}
  String getFileType() {return fileType;}
  String getPath() {return path;}
  DateTime getCreationDate() {return creationDate;}
  int getOwnerId() {return ownerId;}
  Folder getFolderId() {return folder;}

  // rename
  void rename(String newName) {
    name = newName;
  }

  // Method to show dialog to rename a document
  void showRenameDocumentDialog(BuildContext context) {
    final TextEditingController documentNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rennomer le document'),
          content: TextField(
            controller: documentNameController,
            decoration: InputDecoration(
              hintText: name,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Renommer'),
              onPressed: () {
                String docName = documentNameController
                    .text; // Get the document name from the input
                if (docName.isEmpty) docName = name; // If the document name is empty, set it to the previous name
                
                rename(docName); // Rename the document
                docName = ""; // Clear the doc name
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
