import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'package:docare/core/models/user.dart';
import 'package:docare/core/models/folder.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';


class MenuActions with ChangeNotifier {

  Future<void> newFolder(BuildContext context, int indexFolder, VoidCallback onComplete) async {
    final TextEditingController _folderNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nouveau dossier'),
          content: TextField(
            controller: _folderNameController,
            decoration: const InputDecoration(
              hintText: 'Dossier sans titre',
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
              child: const Text('Créer'),
              onPressed: () {
                String folderName = _folderNameController.text; // Get the folder name from the input
                if(folderName.isEmpty) folderName = "Dossier sans titre"; // If the folder name is empty, set it to "Dossier sans titre"
                Folder newFolder = Folder(
                  id: Provider.of<User>(context, listen: false).folderList.length, // id = nombre de dossiers actuels
                  name: folderName, // Nom du dossier
                  parentId: Provider.of<User>(context, listen: false).folderList[indexFolder].id, // dossier parent = dossier actuel
                  folders: [], 
                  files: [],
                  owner: Provider.of<User>(context, listen: false), // Propriétaire = utilisateur actuel
                );
                folderName = ""; // Clear the folder name
                Navigator.of(context).pop(); // Close the dialog
                // Call the callback function after folder creation
                onComplete();
              },
            ),
          ],
        );
      },
    );

    notifyListeners();
  }

  Future<void> newDocument(BuildContext context, VoidCallback onComplete) async {
    final TextEditingController _folderNameController = TextEditingController();
    
    // async pour pouvoir utiliser await
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      // Sélectionner un fichier
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'pdf'
      ], // Extensions de fichier autorisées
    );
    if (result != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Document ajouté'),
            content: Text('Le document a été ajouté avec succès.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
              ),
            ],
          );
        },
      );
    } else {
      // L'utilisateur a annulé la sélection de fichier
      ('Aucun fichier sélectionné.');
    }
  }

    notifyListeners();
  
}

class CustomContextMenuArea extends StatelessWidget {
  final Widget child;
  final VoidCallback updateCallback;
  final int indexFolder;
  final bool isElement;
  CustomContextMenuArea({required this.child, required this.updateCallback, required this.indexFolder, required this.isElement});

  @override
  Widget build(BuildContext context) {
    void contextMenuListener(html.Event event) {
          event.preventDefault();
          html.window.removeEventListener('contextmenu', contextMenuListener);
        }

        html.window.addEventListener('contextmenu', contextMenuListener); // Listen for context menu events

    return GestureDetector(
      onSecondaryTapUp: (details) {

        final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
        if (overlay != null) {
          final RelativeRect position = RelativeRect.fromRect(
            Rect.fromPoints(
              details.globalPosition,
              details.globalPosition,
            ),
            Offset.zero & overlay.size,
          );

          if(isElement == true) // Si le clic est dans la zone du dossier/document
          {
            
          }
          else {
            showMenu(
              context: context,
              position: position,
              items: [
                PopupMenuItem(
                value: 'new_document',
                child: const Text('Nouveau Document'),
                onTap: () => Provider.of<MenuActions>(context, listen: false).newDocument(context, updateCallback),
              ),
              PopupMenuItem(
                value: 'new_folder',
                child: const Text('Nouveau dossier'),
                onTap: () {
                  // Perform the action for creating a new folder
                  Provider.of<MenuActions>(context, listen: false).newFolder(context, indexFolder, updateCallback); // Appel de la fonction newFolder
                },
                
              ),
            ],
            ).then((value) {
            });
          }
          //html.window.removeEventListener('contextmenu', contextMenuListener);
        }
      },
      child: child,
    );
  }
}

