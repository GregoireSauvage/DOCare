import 'package:flutter/material.dart';
import 'package:docare/main.dart';
import 'package:file_picker/file_picker.dart'; // Pour sélectionner un fichier
import 'dart:typed_data'; // Pour convertir un fichier en bytes
import 'package:flutter/services.dart'
    show rootBundle; // Pour charger un fichier depuis les assets
import 'package:provider/provider.dart'; // Pour utiliser le provider
import 'package:docare/core/models/user.dart'; // Classe User
import 'package:docare/features/document/document.dart'; // Classe Document
import 'package:docare/core/models/folder.dart'; // Classe Folder
import 'package:docare/core/models/file_system_entity.dart'; // Classe mère FileSystemEntity pour les dossiers et les documents

import 'package:flutter/foundation.dart';
import 'dart:html' as html; // Pour afficher une image dans un dialogue
import 'dart:ui_web' as ui; // Pour afficher un pdf dans un dialogue

import 'package:docare/core/widgets/footer_web.dart'; // Pour afficher le footer
import 'package:docare/core/utils/context_menu.dart'; // Pour afficher le menu contextuel (clic droit)

import 'package:docare/core/utils/font_size.dart';


class DocumentInterface extends StatefulWidget {
  @override
  _DocumentInterfaceState createState() => _DocumentInterfaceState();
}

// Méthode pour afficher un pdf dans un dialogue
Future<void> _displayPdf(BuildContext context, Uint8List fileBytes) async {
  // Create a Blob from the Uint8List
  final blob = html.Blob([fileBytes], 'application/pdf');
  // Create an object URL for the Blob
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Define a unique ID for the view
  final uniqueId = 'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';

  // Register the view factory if not already registered
  // Note: The new API does not require checking if it's registered
  ui.platformViewRegistry.registerViewFactory(
      uniqueId,
      (int viewId) => html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%');

  // Display the PDF in an AlertDialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Container(
          height: 800, // Set the height of the dialog
          width: 1200,
          child: HtmlElementView(viewType: uniqueId),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Fermer'),
            onPressed: () {
              Navigator.of(context).pop();
              html.Url.revokeObjectUrl(url);
            },
          ),
        ],
      );
    },
  );
}

void newDocument(BuildContext context) async {
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
    PlatformFile file = result.files.first;

    // Vérifiez si le fichier est une image
    if (['jpg', 'jpeg', 'png'].contains(file.extension)) {
      // Convertir en Uint8List
      Uint8List fileBytes = file.bytes!;
      // Créer une image à partir des bytes
      Widget image = Image.memory(fileBytes);

      // Afficher l'image dans un dialogue
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: image,
          actions: <Widget>[
            TextButton(
              child: Text('Fermer'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else if (file.extension == 'pdf') {
      PlatformFile file = result.files.first; // Récupérer le fichier
      Uint8List? fileBytes = file.bytes; // Convertir en Uint8List
      if (fileBytes != null) {
        await _displayPdf(
            context, fileBytes); // Appelle la methode pour afficher le pdf
      }
    } else {
      // Gérer les autres types de fichiers ici
      print('Type de fichier non supporté pour la visualisation directe.');
    }
  } else {
    // L'utilisateur a annulé la sélection de fichier
    print('Aucun fichier sélectionné.');
  }
}

class _DocumentInterfaceState extends State<DocumentInterface> {
  
  // Méthode pour charger un pdf depuis les assets
  Future<Uint8List> loadPdfFromAssets(String path) async {
    final byteData = await rootBundle.load(path);
    return byteData.buffer.asUint8List();
  }

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
                if (folderName.isEmpty)
                  folderName =
                      "Dossier sans titre"; // If the folder name is empty, set it to "Dossier sans titre"
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
                );
                folderName = ""; // Clear the folder name
                updateUI();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Méthode pour afficher une un document (image ou pdf) dans un dialogue
  void _openFile(Document document) async {
    if (document.fileType == 'img') {
      // It's an image
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Image.asset(
                document.path), // Use the path from the document data
            actions: <Widget>[
              Text(document.name),
              SizedBox(
                  width: MediaQuery.of(context).size.width /
                      15), // Ajuster la taille du SizedBox si nécessaire
              TextButton(
                child: const Text('Fermer'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } else if (document.fileType == 'pdf') {
      final fileBytes = await loadPdfFromAssets(
          document.path); // Charge le pdf depuis les assets
      _displayPdf(
          context, fileBytes); // Appelle la methode pour afficher le pdf
    } else {
      print("Type de fichier non supporté pour la visualisation directe.");
    }
  }

  TextEditingController searchController = TextEditingController(); // Contrôleur pour la barre de recherche
  List<FileSystemEntity> filteredEntity = []; // Liste des dossiers/documents filtrés
  int idFolder = 0; // Index du dossier actuel - 0 = /home (ou root)
  int indexFolder = 0;

  @override
  void initState() {
    // Méthode appelée au démarrage de l'application
    super.initState();

    filteredEntity.clear(); // Vide la liste des documents
    //indexFolder = FindFolderIndexWithId(idFolder); // Trouve l'index du dossier actuel
    for (int i = 0;
        i <
            Provider.of<User>(context, listen: false)
                .folderList[indexFolder]
                .folders
                .length;
        i++) {
      filteredEntity.add(Provider.of<User>(context, listen: false)
          .folderList[indexFolder]
          .folders[i]);
    }
    for (int i = 0;
        i <
            Provider.of<User>(context, listen: false)
                .folderList[indexFolder]
                .files
                .length;
        i++) {
      filteredEntity.add(Provider.of<User>(context, listen: false)
          .folderList[indexFolder]
          .files[i]);
    }
  }

  // Méthode pour rechercher un document
  void searchDocuments(String query, indexFolder) {
    List<FileSystemEntity> entity = [];
    for (int i = 0;
        i <
            Provider.of<User>(context, listen: false)
                .folderList[indexFolder]
                .folders
                .length;
        i++) {
      entity.add(Provider.of<User>(context, listen: false)
          .folderList[indexFolder]
          .folders[i]);
    }
    for (int i = 0;
        i <
            Provider.of<User>(context, listen: false)
                .folderList[indexFolder]
                .files
                .length;
        i++) {
      entity.add(Provider.of<User>(context, listen: false)
          .folderList[indexFolder]
          .files[i]);
    }

    if (query.isEmpty) {
      setState(() {
        filteredEntity = entity;
      });
    } else {
      setState(() {
        isElement = false;
        filteredEntity = entity.where((doc) => doc.name.toLowerCase().contains(query.toLowerCase())).toList();
        // filtre aussi dans la liste des tags
        filteredEntity = filteredEntity + entity.where((doc) => (doc is Document) && doc.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))).toList();
        // on enleve les doublons (si un document est trouvé dans les deux listes)
        filteredEntity = filteredEntity.toSet().toList();
      });
    }
  }

  // Méthode pour construire la barre de recherche
  Widget buildTopBar(BuildContext context) {
    // Utilisez MediaQuery pour obtenir la largeur de l'écran
    double screenWidth = MediaQuery.of(context).size.width;

    // Déterminez la taille des boutons en fonction de la largeur de l'écran
    double buttonWidth = screenWidth > 600 ? 200 : screenWidth / 4;
    double padding = screenWidth > 600 ? 10.0 : 8.0;

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(padding),
      color: ColorSettings.backgroundColor,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 8.0),
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
              onChanged: (value) =>
                  searchDocuments(value, indexFolder), // Recherche
            ),
          ),
          const SizedBox(width: 8.0),
          // Utilisez Flexible pour que le bouton "Rechercher" s'adapte à la taille de l'écran
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: buttonWidth),
              child: PopupMenuButton<String>(
                onSelected: (String value) {
                  // Handle the action when an item is selected
                  if (value == 'new_folder') {
                    showCreateFolderDialog(context);
                    setState(() {
                      isElement = false;
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
                  } else if (value == 'new_document') {
                    newDocument(context); // Appelle la méthode pour créer un nouveau document
                    setState(() {
                      isElement = false;
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 13.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add,
                            color: ColorSettings.backgroundColor), // Icon with color
                        SizedBox(
                            width: screenWidth > 600
                                ? 20
                                : 8), // Space between icon and text
                        Align(
                          alignment:
                              Alignment.center, // Align text to the center
                          child: Text(
                            'Nouveau',
                            style: TextStyle(
                              fontSize:
                                  screenWidth > 600 ? 20 : 14, // Font size
                              color: ColorSettings.backgroundColor, // Text color
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8.0),
        ],
      ),
    );
  }

  int FindFolderIndexWithId(int id) {
    for (int i = 0;
        i < Provider.of<User>(context, listen: false).folderList.length;
        i++) {
      if (Provider.of<User>(context, listen: false).folderList[i].id == id) {
        return i;
      }
    }
    return -1;
  }

  String getFolderPath() {
    // Construit le chemin du dossier actuel pour l'afficher
    String path = "";
    Folder currentFolder =
        Provider.of<User>(context, listen: false).folderList[indexFolder];
    int i = indexFolder;
    while (currentFolder.parentId >= 0) {
      // Tant que le dossier actuel n'est pas /home
      path =
          "${Provider.of<User>(context, listen: false).folderList[i].name}/$path"; // Remonte d'un niveau
      currentFolder = Provider.of<User>(context, listen: false)
          .folderList[FindFolderIndexWithId(currentFolder.parentId)];
      i = FindFolderIndexWithId(currentFolder.id);
    }
    path = "/home/$path"; // Ajoute /home au début du chemin
    path = path.substring(0, path.length - 1); // Supprime le dernier /

    return path;
  }


  // Callback function to update UI
  void updateUI() {
    setState(() {
      isElement = false;
      filteredEntity.clear();
      filteredEntity.addAll(Provider.of<User>(context, listen: false)
          .folderList[indexFolder]
          .folders);
      filteredEntity.addAll(Provider.of<User>(context, listen: false)
          .folderList[indexFolder]
          .files);
    });
  }

  bool isElement = false; // True if the context menu is opened on an element (folder or document) - False if the context menu is opened on the background

  Widget _buildImage2() {
    if (ColorSettings.backgroundColor == Color.fromARGB(255, 28, 120, 205)) {
      return Image.asset(
        'assets/images/PFE_logo_bleu2.png',
        width: 50,
        height: 50,
        fit: BoxFit.contain,
      );
    } else if (ColorSettings.backgroundColor ==
        Color.fromARGB(255, 43, 130, 119)) {
      return Image.asset(
        'assets/images/PFE_logo_vert2.png',
        width: 50,
        height: 50,
        fit: BoxFit.contain,
      );
    } else {
      // Si aucune des conditions n'est vraie, vous pouvez retourner une image par défaut ou un widget vide
      return Image.asset(
        'assets/images/PFE_logo_violet2.png',
        width: 50,
        height: 50,
        fit: BoxFit.contain,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String path = getFolderPath();

  html.window.addEventListener('contextmenu', (html.Event event) {
    event.preventDefault();
  });

    return Consumer<MenuActions>(builder: (context, menuActions, child) {
      return Scaffold(
        body: CustomContextMenuArea(
          updateCallback: updateUI,
          indexFolder: indexFolder,
          isElement: isElement,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
            children: <Widget>[
              Container(
                color: ColorSettings.backgroundColor,
                padding: const EdgeInsets.all(14.0),
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
                      child: _buildImage2(),
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
              buildTopBar(context),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: InkWell(
                  // InkWell pour rendre l'image cliquable
                  onTap: () {
                    Folder folder = Provider.of<User>(context, listen: false)
                        .folderList[indexFolder];
                    int parentdIndexFolder = FindFolderIndexWithId(
                        folder.parentId); // Change the current folder index
                    if (parentdIndexFolder < 0) parentdIndexFolder = 0;
                    setState(() {
                      isElement = false;
                      indexFolder = parentdIndexFolder;
                      filteredEntity.clear(); // Clear the list of documents
                      searchController.clear(); // Clear the search bar
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
                  },
                  child: Text(
                    path, // Affiche le chemin du dossier actuel
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: filteredEntity
                        .isEmpty // Si aucun document n'est trouvé dans la recherche ou si aucun document n'a été ajouté
                    ? Text(
                        "Aucun document trouvé",
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      )
                    : Text(
                        "Mes documents",
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(4.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: (MediaQuery.of(context).size.width / 120)
                        .floor(), // le nombre d'éléments par ligne (adapté selon la taille de l'écran)
                    crossAxisSpacing:
                        10.0, // Espace horizontal entre les éléments
                    mainAxisSpacing: 10.0, // Espace vertical entre les éléments
                  ),
                  itemCount: filteredEntity
                      .length, // Remplacer par le nombre réel de documents (ou recherchés)
                  itemBuilder: (context, index) {
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Builder(  // Use Builder to get the correct context for the grid item
                        builder: (itemContext) => InkWell(
                          // Code pour visualiser le document
                          onTap: () {
                            if (filteredEntity[index].type == true) {
                              // Si c'est un dossier

                              Folder folder = filteredEntity[index]
                                  as Folder; // Cast en Folder
                              setState(() {
                                isElement = false;
                                indexFolder = FindFolderIndexWithId(
                                    folder.id); // Change the current folder index
                                filteredEntity
                                    .clear(); // Clear the list of documents
                                searchController.clear(); // Clear the search bar
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
                            } else {
                              // Si c'est un document
                              Document document = filteredEntity[index]
                                  as Document; // Cast en Document
                              _openFile(
                                  document); // Appelle la méthode pour afficher le document
                            }
                          },
                          onSecondaryTap: () {
                            isElement = true;
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
                                document.showRenameDocumentDialog(context, () { // Affiche la boîte de dialogue pour renommer le document
                                  updateUI();
                                }); 
                                
                              }
                              else {
                                Folder folder = filteredEntity[index] as Folder; // Cast en Folder
                                folder.showRenameFolderDialog(context); // Affiche la boîte de dialogue pour renommer le dossier
                              }
                              
                            } else if (value == 'delete') {
                              if(filteredEntity[index] is Folder) {
                                Folder folder = filteredEntity[index] as Folder;
                                Provider.of<User>(context, listen: false).removeFolder(folder.id); // Supprime le dossier

                                Provider.of<User>(context, listen: false).folderList[indexFolder].removeFolder(folder); // Supprime le dossier de la liste des dossiers du dossier parent (dossier actuel

                                
                              } else {
                                Document document = filteredEntity[index] as Document;
                                Provider.of<User>(context, listen: false).removeDocument(document); // Supprime le document/dossier
                                Provider.of<User>(context, listen: false).folderList[indexFolder].removeFile(document); // Supprime le document/dossier de la liste des documents/dossiers du dossier parent (dossier actuel)
                              }
                              updateUI();
                            }
                            
                          });
                          },
                          child: GridTile(
                              footer: Container(
                                padding: const EdgeInsets.all(4.0),
                                color: ColorSettings.backgroundColor,
                                child: Text(
                                  filteredEntity[index].name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              child: filteredEntity[index] is Document
                                  ? (filteredEntity[index] as Document)
                                              .fileType ==
                                          'img'
                                      ? Image.asset(
                                          (filteredEntity[index] as Document)
                                              .path, // Display the image for documents
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'assets/images/pdf_icon.jpeg',
                                          fit: BoxFit.cover,
                                        )
                                  : Image.asset(
                                      'assets/images/folder.png', // Folder icon for folders
                                      fit: BoxFit.cover,
                                    )),
                        ),
                      )
                    );
                  },
                ),
              ),
              MyFooter(), // Affiche le footer
            ],
          ),
        ),
      );
    });
  }
}
