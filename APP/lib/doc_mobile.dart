import 'package:flutter/material.dart';
import 'package:docare/main.dart';
import 'package:file_picker/file_picker.dart'; // Pour sélectionner un fichier
import 'dart:typed_data'; // Pour convertir un fichier en bytes
import 'package:flutter/foundation.dart';

import 'package:provider/provider.dart'; // Pour utiliser le provider
import 'package:docare/user.dart'; // Pour utiliser la classe User
import 'package:docare/document.dart'; // Pour utiliser la classe Document
import 'package:docare/folder.dart'; // Pour utiliser la classe Folder
import 'package:docare/file_system_entity.dart'; // Classe mère FileSystemEntity pour les dossiers et les documents

// imports pour open_filex (pour ouvrir les fichiers)
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DocumentInterface extends StatefulWidget {
  @override
  _DocumentInterfaceState createState() => _DocumentInterfaceState();
}

class _DocumentInterfaceState extends State<DocumentInterface> {

  // Method to show dialog for new folder creation
  void showCreateFolderDialog(BuildContext context) {
    final TextEditingController folderNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nouveau dossier'),
          content: TextField(
            controller: folderNameController,
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
                String folderName = folderNameController
                    .text; // Get the folder name from the input
                if (folderName.isEmpty) folderName = "Dossier sans titre"; // If the folder name is empty, set it to "Dossier sans titre"
                Folder newFolder = Folder(
                  id: Provider.of<User>(context, listen: false)
                      .folderList
                      .length, // id = nombre de dossiers actuels
                  name: folderName, // Nom du dossier
                  parentId: Provider.of<User>(context, listen: false)
                      .folderList[indexFolder]
                      .id, // dossier parent = dossier actuel
                  folders: [],
                  files: [],
                  owner: Provider.of<User>(context,
                      listen: false), // Propriétaire = utilisateur actuel
                  sharedWith: [],
                  );
                folderName = ""; // Clear the folder name
                setState(() {
                  filteredEntity.clear(); // Clear the list of documents
                  // Add folders and files from the selected folder to filteredEntity
                  filteredEntity.addAll(
                      Provider.of<User>(context, listen: false)
                          .folderList[indexFolder]
                          .folders);
                  filteredEntity.addAll(
                      Provider.of<User>(context, listen: false)
                          .folderList[indexFolder]
                          .files);
                });
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // This method uses open_filex to open the file.
  void _openFile(Document file, BuildContext context) async {
    if (file.fileType == 'pdf') {
      // Si le document est un PDF
      final byteData = await rootBundle.load(file.path);
      final tempDir = await getTemporaryDirectory();
      final fileName = file.path.split('/').last;
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(
          byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          flush: true);

      final result = await OpenFilex.open(tempFile.path);

      // If the PDF couldn't be opened, show an error.
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to open the file: ${result.message}"),
          ),
        );
      }
    } else if (file.fileType == 'img') {
      // Si le document est une image
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content:
              Image.asset(file.path), // Assuming `path` is a valid asset path
          actions: <Widget>[
            TextButton(
              child: const Text('Fermer'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  void newDocument() async {
    // async pour pouvoir utiliser await
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      withData: true, // Récupérer les données du fichier
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'pdf'
      ], // Extensions de fichier autorisées
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      // Vérifiez si le fichier est une image
      if (['jpg', 'jpeg', 'png'].contains(file.extension)) {
        // Convertir en Uint8List
        Uint8List? fileBytes = file.bytes;
        if (fileBytes != null) {
          // Proceed with your logic
          Widget image = Image.memory(fileBytes);

          // Ajouter le document à la liste des documents de l'utilisateur
          // TO DO:
        } else {
          // Handle the situation where bytes are not available
          print('Error: File bytes are null');
        }
      } else if (file.extension == 'pdf') {
        // Faire de même pour les PDF
      } else {
        // Gérer les autres types de fichiers ici
        print(
            'Type de fichier non supporté pour la visualisation directe.');
      }
    } else {
      // L'utilisateur a annulé la sélection de fichier
      print('Aucun fichier sélectionné.');
    }
  }

  // Méthode pour construire la barre de recherche
  Widget buildTopBar(BuildContext context) {
    // Utilisez MediaQuery pour obtenir la largeur de l'écran
    double screenWidth = MediaQuery.of(context).size.width;

    // Déterminez la taille des boutons en fonction de la largeur de l'écran
    double buttonWidth = screenWidth > 600 ? 200 : screenWidth / 4;
    double padding = screenWidth > 600 ? 50.0 : 8.0;

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(padding),
      color: Colors.blue,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 8.0), // Espace entre les boutons
          // Expanded fait que la barre de recherche prend le reste de l'espace disponible
          Expanded(
            flex:
                2, // Donne plus de flexibilité à la barre de recherche par rapport aux boutons
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Rechercher un document',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => searchDocuments(value, Provider.of<User>(context, listen: false).folderList[indexFolder]), // Recherche
            ),
          ),
          const SizedBox(width: 16.0),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: buttonWidth),
              child: PopupMenuButton<String>(
                onSelected: (String value) {
                  // Handle the action when an item is selected
                  if (value == 'new_folder') {
                    showCreateFolderDialog(context); // Appelle la méthode pour créer un nouveau dossier
                  } else if (value == 'new_document') {
                    newDocument(); // Appelle la méthode pour créer un nouveau document
                  }
                },
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'new_document',
                      child: Text('Nouveau Document'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'new_folder',
                      child: Text('Nouveau dossier'),
                    ),
                    
                  ];
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Background color
                    borderRadius: BorderRadius.circular(4.0), // Border radius
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // This will center the icon horizontally
                      crossAxisAlignment: CrossAxisAlignment.center, // This will center the icon vertically
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: screenWidth > 700
                        ? Text('Nouveau') // Si l'écran est large (texte)
                        : Icon(Icons.add, color: Colors.blue) // Si l'écran est petit (icone)
                        ),
                        
                        
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextEditingController searchController = TextEditingController(); // Contrôleur pour la barre de recherche
  List<FileSystemEntity> filteredEntity = []; // Liste des dossiers/documents filtrés
  int idFolder = 0; // Index du dossier actuel - 0 = /home (ou root)
  int indexFolder = 0;

  @override
  void initState() {
    // Méthode appelée au démarrage de l'application
    super.initState();
    
    for (int i = 0; i < Provider.of<User>(context, listen: false).folderList[0].folders.length; i++) {
      filteredEntity.add(Provider.of<User>(context, listen: false).folderList[0].folders[i]);
    }
    for (int i = 0; i < Provider.of<User>(context, listen: false).folderList[0].files.length; i++) {
      filteredEntity.add(Provider.of<User>(context, listen: false).folderList[0].files[i]);
    }
  }

 
  // Méthode pour rechercher un document
  void searchDocuments(String query, Folder folder) {
    List<FileSystemEntity> entity = [];
    for (int i = 0; i < folder.folders.length; i++) {
      entity.add(folder.folders[i]);
    }
    for (int i = 0; i < folder.files.length; i++) {
      entity.add(folder.files[i]);
    }

    if (query.isEmpty) {
      setState(() {
        filteredEntity = entity;
      });
    } else {
      setState(() {
        filteredEntity = entity
            .where(
                (doc) => doc.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  // Méthode pour trouver l'index d'un dossier dans la liste des dossiers de l'utilisateur
  int FindFolderIndexWithId(int id) {

    for(int i = 0; i < Provider.of<User>(context, listen: false).folderList.length; i++) {
      if(Provider.of<User>(context, listen: false).folderList[i].id == id) {
        return i;
      }
    }
    return -1;
  }

  String getFolderPath() {
    // Construit le chemin du dossier actuel pour l'afficher
    String path = "";
    Folder currentFolder = Provider.of<User>(context, listen: false).folderList[indexFolder];
    int i = indexFolder;
    while(currentFolder.parentId >= 0) { // Tant que le dossier actuel n'est pas /home 
      path = "${Provider.of<User>(context, listen: false).folderList[i].name}/$path"; // Remonte d'un niveau
      currentFolder = Provider.of<User>(context, listen: false).folderList[FindFolderIndexWithId(currentFolder.parentId)];
      i = FindFolderIndexWithId(currentFolder.id);
    }
    path = "/home/$path"; // Ajoute /home au début du chemin
    path = path.substring(0, path.length - 1); // Supprime le dernier /

    return path;
  }

  @override
  Widget build(BuildContext context) {
    
    String path = getFolderPath();
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
        children: <Widget>[
          Container(
            color: Colors.blue,
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.only(bottom: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                InkWell(
                  // InkWell pour rendre l'image cliquable
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              MyApp()), // Retour à la page d'accueil
                    );
                  },
                  child: Image.asset(
                    'assets/images/docare_logo.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Bienvenue dans votre assistant de gestion de document',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          buildTopBar(context), // Barre de recherche (voir la méthode buildTopBar)
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: InkWell(
                  // InkWell pour rendre l'image cliquable
                  onTap: () {
                    Folder folder = Provider.of<User>(context, listen: false).folderList[indexFolder];
                    int parentdIndexFolder = FindFolderIndexWithId(folder.parentId); // Change the current folder index
                    if(parentdIndexFolder < 0) parentdIndexFolder = 0; 
                    setState(() {
                          indexFolder = parentdIndexFolder;
                          filteredEntity.clear(); // Clear the list of documents
                          searchController.clear(); // Clear the search bar
                          // Add folders and files from the selected folder to filteredEntity
                          filteredEntity.addAll(Provider.of<User>(context, listen: false).folderList[indexFolder].folders);
                          filteredEntity.addAll(Provider.of<User>(context, listen: false).folderList[indexFolder].files);
                        });
                  },
                  child: Text(
                    path, // Affiche le chemin du dossier actuel
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: filteredEntity.isEmpty // Si aucun document n'est trouvé dans la recherche ou si aucun document n'a été ajouté
                ? Text(
                    "Aucun document trouvé",
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  )
                : Text(
                    "Mes documents",
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
          ),
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.all(4.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (MediaQuery.of(context).size.width / 120).floor(), // le nobre d'éléments par ligne (adapté selon la taille de l'écran)
                crossAxisSpacing: 10.0, // Espace horizontal entre les éléments
                mainAxisSpacing: 10.0, // Espace vertical entre les éléments
              ),
              itemCount: filteredEntity.length, // Remplacer par le nombre réel de documents
              itemBuilder: (context, index) {
                return Card(
                  clipBehavior: Clip.antiAlias,
                    child: Builder(  // Use Builder to get the correct context for the grid item
                      builder: (itemContext) => InkWell(
                      onTap: () {
                        if (filteredEntity[index].type == true) {
                          // Si c'est un dossier
                          Folder folder = filteredEntity[index] as Folder; // Cast en Folder

                          setState(() {

                            indexFolder = FindFolderIndexWithId(folder.id); // Change the current folder index
                            filteredEntity.clear(); // Clear the list of documents
                            searchController.clear(); // Clear the search bar
                            // Add folders and files from the selected folder to filteredEntity
                            filteredEntity.addAll(Provider.of<User>(context, listen: false).folderList[indexFolder].folders);
                            filteredEntity.addAll(Provider.of<User>(context, listen: false).folderList[indexFolder].files);
                          });

                        } else {
                          // Si c'est un document
                          Document document = filteredEntity[index] as Document;
                          _openFile(document, context);
                        }
                      },
                      onLongPress: () { // Lorsque l'utilisateur appuie longuement sur un document/dossier
                        final RenderBox itemBox = itemContext.findRenderObject() as RenderBox;
                        final Offset position = itemBox.localToGlobal(Offset.zero);
                        final Size size = itemBox.size; // gets the size of the element

                        // Calculate the bottom left position of the element
                        final Offset bottomLeft = position + Offset(0, size.height);

                        showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            bottomLeft.dx, // Left position
                            bottomLeft.dy, // Top position, which is actually the bottom of the element
                            bottomLeft.dx, // Right position
                            0, // Bottom position
                          ),
                          items: [
                            const PopupMenuItem<String>(
                              value: 'rename',
                              child: Text('Renommer'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ).then((value) {
                          if (value == 'rename') {
                            if(filteredEntity[index] is Document) {
                              Document document = filteredEntity[index] as Document; // Cast en Document
                              document.showRenameDocumentDialog(context); // Affiche la boîte de dialogue pour renommer le document
                            }
                            else {
                              Folder folder = filteredEntity[index] as Folder; // Cast en Folder
                              folder.showRenameFolderDialog(context); // Affiche la boîte de dialogue pour renommer le dossier
                            }
                            setState(() {
                              filteredEntity.clear(); // Clear the list of documents
                              // Add folders and files from the selected folder to filteredEntity
                              filteredEntity.addAll(
                                  Provider.of<User>(context, listen: false)
                                      .folderList[indexFolder]
                                      .folders);
                              filteredEntity.addAll(
                                  Provider.of<User>(context, listen: false)
                                      .folderList[indexFolder]
                                      .files);
                            });
                          } else if (value == 'delete') {
                            // Code for deleting
                          }
                        });
                      },
                      
                      child: GridTile(
                        footer: Container(
                          padding: const EdgeInsets.all(4.0),
                          color: Colors.blue.withOpacity(0.8),
                          child: Text(
                            filteredEntity[index].name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        child: filteredEntity[index] is Document
                            ? (filteredEntity[index] as Document).fileType == 'img'
                                ? Image.asset(
                                    (filteredEntity[index] as Document).path, // Display the image for documents
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/images/pdf_icon.jpeg', 
                                    fit: BoxFit.cover,
                                  )
                            : Image.asset(
                                    'assets/images/folder.png', // Folder icon for folders
                                    fit: BoxFit.cover,
                                  )
                      ),
                    ),
                  )
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
