import 'document.dart';
import 'user.dart';
import 'file_system_entity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docare/user.dart';

class Folder extends FileSystemEntity {

  int id;
  String name;
  int parentId;
  List<Folder> folders;
  List<Document> files;
  User owner;           // full access
  List <User> sharedWith; // read only (?)
  

  // Constructor
  Folder({
    required this.id,
    required this.name,
    required this.parentId,
    required this.folders,
    required this.files,
    required this.owner,
    required this.sharedWith,
  }) : super(name: name, type: true) {
    
    if(parentId >= 0) {
      for(int i = 0; i < owner.folderList.length; i++){ // Loop through the list of folders of the owner
        if(owner.folderList[i].id == parentId){ // If the parent folder is found
          owner.folderList[i].addFolder(this); // Add this folder to the parent folder
        }
      }
    }
    owner.addFolder(this); // Add this folder to the list of folders of the owner
  }

  // Add a folder to the list of folders
  void addFolder(Folder folder) {
    folders.add(folder);
  }
  // Remove a folder from the list of folders
  void removeFolder(Folder folder) {
    folders.remove(folder);
  }
  
  // Add a file to the list of files
  void addFile(Document file) {
    files.add(file);
  }
  // Remove a file from the list of files
  void removeFile(Document file) {
    files.remove(file);
  }

  // Add a user to the list of users with read only access
  void addUser(User user) {
    sharedWith.add(user);
  }
  // Remove a user from the list of users with read only access
  void removeUser(User user) {
    sharedWith.remove(user);
  }

  // Getters
  int getId() {return id;}
  String getName() {return name;}
  int getParentId() {return parentId;}
  List<Folder> getFolders() {return folders;}
  List<Document> getFiles() {return files;}
  User getOwnerId() {return owner;}
  List <User> getSharedWith() {return sharedWith;}

  // rename folder
  void rename(String newName) {
    name = newName;
  }

  // Method to show dialog to rename a folder
  void showRenameFolderDialog(BuildContext context) {
    final TextEditingController folderNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rennomer le dossier'),
          content: TextField(
            controller: folderNameController,
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
                String folderName = folderNameController
                    .text; // Get the document name from the input
                if (folderName.isEmpty) folderName = name; // If the document name is empty, set it to the previous name
                
                rename(folderName); // Rename the document
                folderName = ""; // Clear the doc name
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}