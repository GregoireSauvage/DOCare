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
  List<String> tags; // liste des tags
  DateTime creationDate;
  int ownerId; // id de l'utilisateur propriétaire du document
  Folder folder; // id du dossier dans lequel se trouve le document

  Document({
    required this.id,
    required this.title,
    required this.fileType,
    required this.path,
    required this.tags,
    required this.creationDate,
    required this.ownerId,
    required this.folder,
  
  }) : super(name: title, type: false) {
    folder.addFile(this); // Ajout du document au dossier
  }

  Document.simpleConstructor({
    required this.id,
    required this.title,
    required this.fileType,
    required this.path,
    required this.tags,
    required this.creationDate,
    required this.ownerId,
    required this.folder,
  }) : super(name: title, type: false);
  

  // Getters
  int getId() {return id;}
  String getTitle() {return title;}
  String getFileType() {return fileType;}
  String getPath() {return path;}
  List<String> getTags() {return tags;}
  DateTime getCreationDate() {return creationDate;}
  int getOwnerId() {return ownerId;}
  Folder getFolderId() {return folder;}

  // rename
  void rename(String newName) {
    name = newName;
  }

  // add a tag
  void addTag(String tag) {
    tags.add(tag);
  }

  // modify tags
  void modifyTag(List<String> newTags) {
    tags.clear();
    for (String tag in newTags){
      tags.add(tag);
    }
  }

  void modifyOwner(int newOwnerId) {
    ownerId = newOwnerId;
  }

  // Method to show dialog to rename a document
  Future<void> showRenameDocumentDialog(BuildContext context, VoidCallback onRenameSuccess) async {
    final TextEditingController documentNameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Renommer le document'),
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
                documentNameController.clear(); // Clear the doc name
                onRenameSuccess(); // Call the callback function after document rename
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}


class Document_BDD {
  int id=0;
  String title="";
  String fileType="";
  String path="";  // chemin du fichier
  List<String> tags=[]; // liste des tags
  DateTime creationDate=DateTime.now();
  int ownerId=0; // id de l'utilisateur propriétaire du document
  int folderId=0; // id du dossier dans lequel se trouve le document

  
  Document_BDD({
    required Document document,
  }) {
    id = document.id;
    title = document.title;
    fileType = document.fileType;
    path = document.path;
    tags = document.tags;
    creationDate = document.creationDate;
    ownerId = document.ownerId;
    folderId = document.folder.id;
  } 
}