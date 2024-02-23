import 'package:flutter/material.dart';
import 'package:docare/main.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Pour charger un fichier depuis les assets
import 'package:provider/provider.dart'; // Pour utiliser le provider
import 'package:docare/core/models/user.dart'; // Classe User
import 'package:docare/core/models/folder.dart'; // Classe Folder

import 'package:flutter/foundation.dart';
import 'package:docare/core/utils/hyperlink.dart'; // Pour afficher un lien hypertexte
import 'package:docare/features/demarches/demarche.dart'; // Pour les demarches administratives
import 'package:docare/features/document/document.dart'; // Pour les documents

import 'package:docare/core/widgets/pdf_custom_viewer.dart'; // Pour afficher un document
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_tts/flutter_tts.dart'; //Lecture
import 'package:docare/core/utils/font_size.dart'; // Pour utiliser la classe FontSizeSettings
import 'package:file_picker/file_picker.dart'; // Pour sélectionner un fichier

class DemarcheSelectedInterface extends StatefulWidget {
  final Demarche demarche;

  DemarcheSelectedInterface({Key? key, required this.demarche}); // Constructeur

  @override
  _DemarcheSelectedInterfaceState createState() =>
      _DemarcheSelectedInterfaceState();
}

class _DemarcheSelectedInterfaceState extends State<DemarcheSelectedInterface> {
  // Méthode pour charger un pdf depuis les assets
  Future<Uint8List> loadPdfFromAssets(String path) async {
    final byteData = await rootBundle.load(path);
    return byteData.buffer.asUint8List();
  }

  TextEditingController searchController =
      TextEditingController(); // Contrôleur pour la barre de recherche
  List<Demarche> filteredProcedure = []; // Liste des démarches filtrés
  int idFolder = 0; // Index du dossier actuel - 0 = /home (ou root)
  int indexFolder = 0;
  Map<String, List<Document>> documentsFournisSuggeres = {};
  FlutterTts flutterTts = FlutterTts(); //fonction de lecture

  @override
  void initState() {
    super.initState();

    flutterTts = FlutterTts(); //fonction de lecture
    flutterTts.setLanguage("fr-FR"); //fonction de lecture

    filteredProcedure.clear();
    filteredProcedure.add(widget.demarche);

    // Parcourir chaque document nécessaire
    for (String docNecessaire in widget.demarche.documentsNecessaires) {
      // Initialiser la liste pour ce document nécessaire dans le Map
      documentsFournisSuggeres[docNecessaire] = [];

      // Parcourir tous les dossiers et fichiers de l'utilisateur
      for (Folder folder
          in Provider.of<User>(context, listen: false).folderList) {
        for (Document file in folder.files) {
          // Vérifie si le nom du fichier correspond à un document nécessaire
          if (docNecessaire == file.name) {
            documentsFournisSuggeres[docNecessaire]?.add(file);
            print("trouvé: ${file.tags}");
          }
          for (int i = 0;
              i < widget.demarche.tagsDocumentsNecessaires.length;
              i++) {
            for (int j = 0; j < file.tags.length; j++) {
              if (widget.demarche.tagsDocumentsNecessaires[i] == file.tags[j]) {
                documentsFournisSuggeres[docNecessaire]?.add(file);
                print("trouvé: ${file.tags}");
              }
            }
          }
        }
      }
    }

    // Iterate through the map to remove duplicates in each list
    documentsFournisSuggeres.forEach((key, value) {
      // Convert the list to a set to remove duplicates, then back to a list
      documentsFournisSuggeres[key] = value.toSet().toList();
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  // Callback function to update UI
  void updateUI() {
    setState(() {
      filteredProcedure.clear();
      filteredProcedure.add(widget.demarche);
    });
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

  bool isExpanded = true; // Etat de l'expansion de la description

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
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
        children: <Widget>[
          Container(
            color: ColorSettings.backgroundColor,
            padding: const EdgeInsets.all(30.0),
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
                Expanded(
                  child: Text(
                    widget.demarche.name, // Nom de la démarche
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
              //ca
              visible:
                  isExpanded, // Affiche ou cache les widgets en fonction de l'état
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 30, top: 30.0, bottom: 6.0, right: 30.0),
                  child: Text(
                    widget.demarche.description, // Description de la démarche
                    style: TextStyle(
                        fontSize: FontSizeSettings.fontSize,
                        color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 30.0, bottom: 20.0, right: 30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Alignement des éléments à droite
                    children: [
                      Hyperlink(
                          widget.demarche.lien,
                          widget.demarche
                              .name), // Lien hypertexte pour la démarche
                      SizedBox(
                          width:
                              20.0), // Ajoute un espace de 20 pixels entre les deux éléments
                      InkWell(
                        onTap: () {
                          _speak(widget.demarche.description);
                        },
                        child: Icon(
                          Icons.volume_up,
                          size: 48.0, // Taille de l'icône
                          color: ColorSettings.backgroundColor, // Couleur de l'icône
                        ),
                      ),
                    ],
                  ),
                ),
              ])),
          IconButton(
            icon: Icon(isExpanded
                ? Icons.arrow_drop_up
                : Icons
                    .arrow_drop_down), // Utilise une icône de flèche vers le haut ou vers le bas en fonction de l'état
            onPressed: () {
              setState(() {
                isExpanded =
                    !isExpanded; // Inverse l'état (développé -> caché ou caché -> développé)
              });
            },
          ),
          const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Documents à fournir pour compléter la démarche",
                  style: TextStyle(fontSize: 20, color: Colors.grey))),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    (MediaQuery.of(context).size.width / 330).floor(),
                crossAxisSpacing: 20.0,
                mainAxisSpacing: 20.0,
                childAspectRatio: 3, // Adjusted for wider tiles
              ),
              itemCount: widget.demarche.documentsNecessaires.length,
              itemBuilder: (context, index) {
                String docNecessaire =
                    widget.demarche.documentsNecessaires[index];
                // Assuming you have a map like the one suggested earlier
                List<Document> matchingDocs =
                    documentsFournisSuggeres[docNecessaire] ?? [];
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: const Color.fromRGBO(158, 158, 158, 1)),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (matchingDocs.isNotEmpty && index < matchingDocs.length) {
                        _openFile(matchingDocs[index], context);
                      } else {
                        newDocument();
                      }
                    },
                    onLongPress: () {
                      if (matchingDocs.isNotEmpty && index < matchingDocs.length) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Ajouter un document'),
                            content: Text('Voulez-vous changer le document ${matchingDocs[index].name} pour la démarche ${widget.demarche.name} ?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close the dialog
                                  newDocument();
                                },
                                child: const Text('Oui'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(), // Close the dialog
                                child: const Text('Non'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        newDocument();
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledForegroundColor: Colors.grey,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 20.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          docNecessaire,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ColorSettings.backgroundColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Conditional display based on whether matchingDocs has elements
                        Text(
                          (matchingDocs.isNotEmpty && index < matchingDocs.length)
                              ? matchingDocs[index].name // Display the name of the first document if available
                              : "Ajouter un document", // Display this message if no documents are found
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ColorSettings.backgroundColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Icon(
                          (matchingDocs.isNotEmpty && index < matchingDocs.length)
                              ? Icons.check_circle
                              : Icons
                                  .add, // Display a checkmark if documents are found, or a plus sign if not
                          color: ColorSettings.backgroundColor,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
