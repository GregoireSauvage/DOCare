import 'package:flutter/material.dart';
import 'package:docare/main.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Pour charger un fichier depuis les assets
import 'package:flutter/foundation.dart';
import 'package:docare/hyperlink.dart'; // Pour afficher un lien hypertexte
import 'package:docare/footer_web.dart'; // Pour afficher le footer
import 'package:docare/document.dart'; // Pour les documents
import 'package:docare/demarche.dart'; // Pour les demarches administratives
import 'package:flutter_tts/flutter_tts.dart'; //Lecture
import 'package:docare/folder.dart'; // Pour les dossiers
import 'package:provider/provider.dart'; // Pour utiliser le provider
import 'package:docare/user.dart'; // Pour utiliser la classe User
import 'package:docare/font_size.dart'; // Pour utiliser la classe FontSizeSettings

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
    print("Selected procedure: ${widget.demarche.name}");
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
          if (docNecessaire == file.name ||
              widget.demarche.tagsDocumentsNecessaires.contains(file.tags)) {
            documentsFournisSuggeres[docNecessaire]?.add(file);
          }
        }
      }
    }
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

  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
        children: <Widget>[
          Container(
            color: Colors.blue,
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
                  child: Image.asset(
                    'assets/images/docare_logo2.png',
                    width: 50,
                    height: 50,
                  ),
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
                          color: Colors.blue, // Couleur de l'icône
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
                      if (matchingDocs.isNotEmpty) {
                        var linkedDocument = matchingDocs[0];
                        print("Opening document: $linkedDocument.name");
                      } else {
                        // If no document is linked, do nothing for now
                        print("No document linked to this requirement.");
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
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Conditional display based on whether matchingDocs has elements
                        Text(
                          matchingDocs.isNotEmpty
                              ? matchingDocs[0]
                                  .name // Display the name of the first document if available
                              : "Ajouter un document", // Display this message if no documents are found
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Icon(
                          matchingDocs.isNotEmpty
                              ? Icons.check_circle
                              : Icons
                                  .add, // Display a checkmark if documents are found, or a plus sign if not
                          color: Colors.blue,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          MyFooter(),
        ],
      ),
    );
  }
}
