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
  int ownerId; // id de l'utilisateur propriétaire du document
  Folder folder; // id du dossier dans lequel se trouve le document

  Document({
    required this.id,
    required this.title,
    required this.fileType,
    required this.path,
    required this.tags,
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
    required this.ownerId,
    required this.folder,
  }) : super(name: title, type: false);
  
  Document.fromJason(Map<String, Object?> json) : this(
    id: json['id']! as int,
    title: json['title']! as String,
    fileType: json['fileType']! as String,
    path: json['path']! as String,
    tags: json['tags']! as List<String>,
    ownerId: json['ownerId']! as int,
    folder: json['folder']! as Folder,
  );

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'fileType': fileType,
      'path': path,
      'tags': tags,
      'ownerId': ownerId,
      'folder': folder,
    };
  }

  // Getters
  int getId() {return id;}
  String getTitle() {return title;}
  String getFileType() {return fileType;}
  String getPath() {return path;}
  List<String> getTags() {return tags;}
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
  int id;
  String title;
  String fileType;
  String path="";  // chemin du fichier
  List<String> tags; // liste des tags
  int ownerId; // id de l'utilisateur propriétaire du document
  int folderId; // id du dossier dans lequel se trouve le document


  Document_BDD({
    required this.id,
    required this.title,
    required this.fileType,
    required this.path,
    required this.tags,
    required this.ownerId,
    required this.folderId,
  });

  Document_BDD.fromJason(Map<String, dynamic> json) : this(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    fileType: json['fileType'] as String? ?? '',
    path: json['path'] as String? ?? '',
    tags: (json['tags'] as List<dynamic>?)?.map((item) => item as String).toList() ?? [],
    ownerId: json['ownerId'] as int? ?? 0,
    folderId: json['folder'] is int ? json['folder'] as int : int.tryParse(json['folder'] as String? ?? '') ?? 0,
  );


  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'fileType': fileType,
      'path': path,
      'tags': tags,
      'ownerId': ownerId,
      'folder': folderId,
    };
  }
}