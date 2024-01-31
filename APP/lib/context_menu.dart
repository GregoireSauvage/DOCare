import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'package:docare/user.dart';
import 'package:docare/folder.dart';

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
                  sharedWith: [],
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

  void newDocument() {
    // Logic to create a new document
    notifyListeners();
  }
}

class CustomContextMenuArea extends StatelessWidget {
  final Widget child;
  final VoidCallback updateCallback;
  final int indexFolder;
  CustomContextMenuArea({required this.child, required this.updateCallback, required this.indexFolder});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) {
        void contextMenuListener(html.Event event) {
          event.preventDefault();
          html.window.removeEventListener('contextmenu', contextMenuListener);
        }

        html.window.addEventListener('contextmenu', contextMenuListener);

        final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
        if (overlay != null) {
          final RelativeRect position = RelativeRect.fromRect(
            Rect.fromPoints(
              details.globalPosition,
              details.globalPosition,
            ),
            Offset.zero & overlay.size,
          );

          if(details.globalPosition.dy > 300) // Si le clic est dans la zone du dossier
          {
            showMenu(
              context: context,
              position: position,
              items: [
              PopupMenuItem(
                value: 'rename',
                child: const Text('Renommer'),
                onTap: () {
                  // Perform the action for creating a new folder
                  print("Renommer");
                },
                
              ),
              PopupMenuItem(
                value: 'delete',
                child: const Text('Supprimer'),
                onTap: () {

                },
              ),
            ],
            ).then((value) {
            });
          }
          else {
            showMenu(
              context: context,
              position: position,
              items: [
              PopupMenuItem(
                value: 'new_folder',
                child: const Text('Nouveau dossier'),
                onTap: () {
                  // Perform the action for creating a new folder
                  Provider.of<MenuActions>(context, listen: false).newFolder(context, indexFolder, updateCallback); // Appel de la fonction newFolder
                },
                
              ),
              PopupMenuItem(
                value: 'new_document',
                child: const Text('Nouveau Document'),
                onTap: () => Provider.of<MenuActions>(context, listen: false).newDocument(),
              ),
            ],
            ).then((value) {
            });
          }
          
        }
      },
      child: child,
    );
  }
}

