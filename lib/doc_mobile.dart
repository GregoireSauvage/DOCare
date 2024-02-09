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
import 'package:cunning_document_scanner/cunning_document_scanner.dart'; // Pour scanner un document
import 'package:docare/scanner_UI_mobile.dart'; // Pour scanner un document

import 'package:docare/font_size.dart';
import 'package:http/http.dart' as http;
// imports firebase
import 'package:docare/services/database_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

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
                refreshUI();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Method to show dialog for new folder creation
  void showDeleteEntityDialog(BuildContext context, FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'Supprimer le ${entity is Document ? 'document' : 'dossier'}'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Supprimer'),
              onPressed: () {
                showDeleteEntityDialog(context,
                    entity); // Appelle la méthode pour créer un nouveau dossier
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
      try {
        // Assuming `file.path` is a URL to the PDF
        final response = await http.get(Uri.parse(file.path));

        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final fileName = file.path.split('/').last;
          final tempFile = File('${tempDir.path}/$fileName');

          // Write the bytes of the response to a file
          await tempFile.writeAsBytes(response.bodyBytes, flush: true);

          // Open the file with any PDF reader
          final result = await OpenFilex.open(tempFile.path);

          // If the PDF couldn't be opened, show an error.
          if (result.type != ResultType.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to open the file: ${result.message}"),
              ),
            );
          }
        } else {
          throw Exception('Failed to load the PDF file');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
          ),
        );
      }
    } else if (file.fileType == 'img') {
      // Si le document est une image
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content:
              Image.network(file.path), // Assuming `path` is a valid asset path
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

  void refreshUI() {
    setState(() {
      filteredEntity.clear();
      filteredEntity.addAll(Provider.of<User>(context, listen: false)
          .folderList[indexFolder]
          .folders);
      filteredEntity.addAll(Provider.of<User>(context, listen: false)
          .folderList[indexFolder]
          .files);

      // print all the documents of the user
    });
    for(int i = 0; i < Provider.of<User>(context, listen: false).folderList.length; i++) {
      print("DOSSIER $i : ${Provider.of<User>(context, listen: false).folderList[i].name}");
      for(int j = 0; j < Provider.of<User>(context, listen: false).folderList[i].files.length; j++) {
        print("fichier $j : ${Provider.of<User>(context, listen: false).folderList[i].files[j].title}");
      }
    }
  }

  void newDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
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
      // Determine the directory based on file type
      String directory = file.extension == 'pdf' ? 'pdfs' : 'images';
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${file.extension}';

      // Upload the document file to Firebase Storage
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('$directory/$fileName');

      // Convert Uint8List to File
      List<int> bytes = file.bytes!;
      Uint8List byteList = Uint8List.fromList(bytes);

      final tempDir = await getTemporaryDirectory();
      File tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(byteList);

      await ref.putFile(tempFile);

      // Get the download URL of the uploaded document
      String downloadUrl = await ref.getDownloadURL();
      print(downloadUrl);
      String type = "";
      if(file.extension.toString() == 'pdf') {
        type = 'pdf';
      }
      else {
        type = 'img';
      }

      Document doc = Document(
          id: 0,
          title: file.name,
          fileType: type,
          path: downloadUrl,
          tags: [],
          ownerId: 2,
          folder: Provider.of<User>(context, listen: false).folderList[indexFolder]);
      Document_BDD doc_bdd = Document_BDD(
          id: 2,
          title: file.name,
          fileType: type,
          path: downloadUrl,
          tags: [],
          ownerId: Provider.of<User>(context, listen: false).userId,
          folderId: doc.folder.id);

      DatabaseService().addDocument_bdd(doc_bdd);
// Add your logic for handling different file types here
      if (['jpg', 'jpeg', 'png'].contains(file.extension)) {
        // Proceed with your logic for images
      } else if (file.extension == 'pdf') {
        // Proceed with your logic for PDFs
      } else {
        // Handle other file types
      }
    } else {
      // Handle the case where no file is selected
      print('No file selected.');
    }
    initBDDListener();
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
      color: ColorSettings.backgroundColor,
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
              onChanged: (value) => searchDocuments(
                  value,
                  Provider.of<User>(context, listen: false)
                      .folderList[indexFolder]), // Recherche
            ),
          ),
          const SizedBox(width: 16.0),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: buttonWidth),
              child: PopupMenuButton<String>(
                onSelected: (String value) async {
                  if (value == 'scan_document') {
                    List<String> pictures =
                        await CunningDocumentScanner.getPictures(true) ?? [];
                    if (pictures.isNotEmpty && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DocumentScannerUI(pictures: pictures),
                        ),
                      );
                    }
                  } else if (value == 'import_document') {
                    newDocument(); // Appelle la méthode pour créer un nouveau document
                  } else if (value == 'new_folder') {
                    showCreateFolderDialog(
                        context); // Appelle la méthode pour créer un nouveau dossier
                  }
                },
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'scan_document',
                      child: Text('Scanner un document'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'import_document',
                      child: Text('Import un document'),
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
                        horizontal: 12.0, vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment
                          .center, // This will center the icon horizontally
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // This will center the icon vertically
                      children: [
                        Align(
                            alignment: Alignment.center,
                            child: screenWidth > 700
                                ? Text(
                                    'Nouveau') // Si l'écran est large (texte)
                                : Icon(Icons.add,
                                    color: ColorSettings
                                        .backgroundColor) // Si l'écran est petit (icone)
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

  TextEditingController searchController =
      TextEditingController(); // Contrôleur pour la barre de recherche
  List<FileSystemEntity> filteredEntity =
      []; // Liste des dossiers/documents filtrés
  int idFolder = 0; // Index du dossier actuel - 0 = /home (ou root)
  int indexFolder = 0;
  List<String> _pictures = [];

  @override
  void initState() {
    super.initState();
    // Set up the listener for the Firestore documents
    initBDDListener();

    for (int i = 0;
        i <
            Provider.of<User>(context, listen: false)
                .folderList[0]
                .folders
                .length;
        i++) {
      filteredEntity.add(
          Provider.of<User>(context, listen: false).folderList[0].folders[i]);
    }
    for (int i = 0;
        i <
            Provider.of<User>(context, listen: false)
                .folderList[0]
                .files
                .length;
        i++) {
      filteredEntity.add(
          Provider.of<User>(context, listen: false).folderList[0].files[i]);
    }
  }

  void createDocumentsFromDBB(List<Document_BDD> documentsBDD) {
    List<Document> documents = [];
    for (int i = 0;
        i < Provider.of<User>(context, listen: false).folderList.length;
        i++) {
      //Provider.of<User>(context, listen: false).folderList[i].files.clear();
        }
    for (int i = 0; i < documentsBDD.length; i++) {
      int index = findFolderIndexWithId(documentsBDD[i].folderId);
      Document newDoc = Document(
        id: documentsBDD[i].id,
        title: documentsBDD[i].title,
        fileType: documentsBDD[i].fileType,
        path: documentsBDD[i].path,
        tags: documentsBDD[i].tags,
        ownerId: documentsBDD[i].ownerId,
        folder: Provider.of<User>(context, listen: false).folderList[index],
      );
      documents.add(newDoc);
      
    }
    documentsBDD.clear();
    Provider.of<User>(context, listen: false).folderList[indexFolder].files.clear();
    Provider.of<User>(context, listen: false).folderList[indexFolder].files = documents;
  }

  void initBDDListener() {
    List<Document_BDD> documentsBDD = [];
    DatabaseService().getDocuments().listen((List<Document_BDD> docs) {
      //createDocumentsFromDBB();
      // Do something with the fetched documents
      documentsBDD = docs;

      // Assign the documents to a state variable that your widget will use to build the UI
      createDocumentsFromDBB(documentsBDD);
    }, onError: (e) {
      // Handle any errors that occur during the fetch
      print("Error fetching documents: $e");
    });
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
        // filtre aussi dans la liste des tags
        filteredEntity = filteredEntity +
            entity
                .where((doc) =>
                    (doc is Document) &&
                    doc.tags.any((tag) =>
                        tag.toLowerCase().contains(query.toLowerCase())))
                .toList();
        // on enleve les doublons (si un document est trouvé dans les deux listes)
        filteredEntity = filteredEntity.toSet().toList();
      });
    }
  }

  // Méthode pour trouver l'index d'un dossier dans la liste des dossiers de l'utilisateur
  int findFolderIndexWithId(int id) {
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
          .folderList[findFolderIndexWithId(currentFolder.parentId)];
      i = findFolderIndexWithId(currentFolder.id);
    }
    path = "/home/$path"; // Ajoute /home au début du chemin
    path = path.substring(0, path.length - 1); // Supprime le dernier /

    return path;
  }

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
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
        children: <Widget>[
          Container(
            color: ColorSettings.backgroundColor,
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
                              const MyApp()), // Retour à la page d'accueil
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
          buildTopBar(
              context), // Barre de recherche (voir la méthode buildTopBar)
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: InkWell(
              // InkWell pour rendre l'image cliquable
              onTap: () {
                Folder folder = Provider.of<User>(context, listen: false)
                    .folderList[indexFolder];
                int parentdIndexFolder = findFolderIndexWithId(
                    folder.parentId); // Change the current folder index
                if (parentdIndexFolder < 0) parentdIndexFolder = 0;
                setState(() {
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
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.all(4.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (MediaQuery.of(context).size.width / 120)
                    .floor(), // le nobre d'éléments par ligne (adapté selon la taille de l'écran)
                crossAxisSpacing: 10.0, // Espace horizontal entre les éléments
                mainAxisSpacing: 10.0, // Espace vertical entre les éléments
              ),
              itemCount: filteredEntity
                  .length, // Remplacer par le nombre réel de documents
              itemBuilder: (context, index) {
                return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Builder(
                      // Use Builder to get the correct context for the grid item
                      builder: (itemContext) => InkWell(
                        onTap: () {
                          if (filteredEntity[index].type == true) {
                            // Si c'est un dossier
                            Folder folder = filteredEntity[index]
                                as Folder; // Cast en Folder

                            setState(() {
                              indexFolder = findFolderIndexWithId(
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
                            Document document =
                                filteredEntity[index] as Document;
                            _openFile(document, context);
                          }
                        },
                        onLongPress: () {
                          // Lorsque l'utilisateur appuie longuement sur un document/dossier
                          final RenderBox itemBox =
                              itemContext.findRenderObject() as RenderBox;
                          final Offset position =
                              itemBox.localToGlobal(Offset.zero);
                          final Size size =
                              itemBox.size; // gets the size of the element

                          // Calculate the bottom left position of the element
                          final Offset bottomLeft =
                              position + Offset(0, size.height);

                          showMenu(
                            context: context,
                            position: RelativeRect.fromLTRB(
                              bottomLeft.dx, // Left position
                              bottomLeft
                                  .dy, // Top position, which is actually the bottom of the element
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
                              if (filteredEntity[index] is Document) {
                                Document document = filteredEntity[index]
                                    as Document; // Cast en Document
                                document.showRenameDocumentDialog(context, () {
                                  // Affiche la boîte de dialogue pour renommer le document
                                  refreshUI();
                                });
                              } else {
                                Folder folder = filteredEntity[index]
                                    as Folder; // Cast en Folder
                                folder.showRenameFolderDialog(
                                    context); // Affiche la boîte de dialogue pour renommer le dossier
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
                              if (filteredEntity[index] is Folder) {
                                Folder folder = filteredEntity[index] as Folder;
                                Provider.of<User>(context, listen: false)
                                    .removeFolder(
                                        folder.id); // Supprime le dossier

                                Provider.of<User>(context, listen: false)
                                    .folderList[indexFolder]
                                    .removeFolder(
                                        folder); // Supprime le dossier de la liste des dossiers du dossier parent (dossier actuel
                              } else {
                                Document document =
                                    filteredEntity[index] as Document;
                                Provider.of<User>(context, listen: false)
                                    .removeDocument(
                                        document); // Supprime le document/dossier
                                Provider.of<User>(context, listen: false)
                                    .folderList[indexFolder]
                                    .removeFile(
                                        document); // Supprime le document/dossier de la liste des documents/dossiers du dossier parent (dossier actuel)
                              }
                              refreshUI();
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
                                    ? Image.network(
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
                    ));
              },
            ),
          ),
        ],
      ),
    );
  }
}
