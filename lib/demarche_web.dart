import 'package:docare/font_size.dart';
import 'package:flutter/material.dart';
import 'package:docare/main.dart';
import 'package:file_picker/file_picker.dart'; // Pour sélectionner un fichier
import 'dart:typed_data'; // Pour convertir un fichier en bytes
import 'package:flutter/services.dart'
    show rootBundle; // Pour charger un fichier depuis les assets
import 'package:provider/provider.dart'; // Pour utiliser le provider
import 'package:docare/user.dart'; // Classe User
import 'package:docare/document.dart'; // Classe Document
import 'package:docare/folder.dart'; // Classe Folder

import 'package:flutter/foundation.dart';
import 'dart:html' as html; // Pour afficher une image dans un dialogue
import 'dart:ui_web' as ui; // Pour afficher un pdf dans un dialogue

import 'package:docare/footer_web.dart'; // Pour afficher le footer
import 'package:docare/demarche.dart'; // Pour les demarches administratives
import 'package:docare/demarche_selected_web.dart'; // Pour la page de démarche sélectionnée
import 'package:url_launcher/url_launcher.dart';

import 'package:docare/font_size.dart';

class DemarcheInterface extends StatefulWidget {
  @override
  _DemarcheInterfaceState createState() => _DemarcheInterfaceState();
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

class _DemarcheInterfaceState extends State<DemarcheInterface> {
  
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
  List<Demarche> filteredProcedure = []; // Liste des démarches filtrés
  int idFolder = 0; // Index du dossier actuel - 0 = /home (ou root)
  int indexFolder = 0;
  
  Demarche demarche1 = Demarche(
    id: 1,
    name: 'Demande RQTH',
    description: 'La reconnaissance de la qualité de travailleur handicapé (RQTH) permet de bénéficier de mesures permettant de trouver un emploi ou de le conserver. La RQTH est attribuée pour une durée d’un à dix ans ou sans limite de durée dans certaines situations.',
    lien: "https://www.monparcourshandicap.gouv.fr/aides/la-reconnaissance-de-la-qualite-de-travailleur-handicape-rqth",
    documentsNecessaires: [
      "Carte d'identité",
      "Certificat médical",
      "Formulaire de demande MDPH",
      "justificatif de domicile",
    ],
    tagsDocumentsNecessaires: [
      "document d'identités",
      "certificat médical",
      "RQTH",
      "domicile",
    ],
    documentsFournis: [],
  );

  @override
  void initState() {
    // Méthode appelée au démarrage de l'application
    super.initState();

    filteredProcedure.clear(); // Vide la liste des démarches
    // Ajoute les démarches de la liste de l'utilisateur à filteredProcedure
    filteredProcedure.add(demarche1);
  }

  // Méthode pour rechercher une démarche
  void searchDocuments(String query, indexFolder) {
    List<Demarche> demarches = [];
    demarches.add(demarche1); // faire la liste des démarches

    if (query.isEmpty) {
      setState(() {
        filteredProcedure = demarches;
      });
    } else {
      setState(() {
        isElement = false;
        filteredProcedure = demarches
            .where(
                (doc) => doc.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
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
                hintText: 'Rechercher une démarche',
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



  // Callback function to update UI
  void updateUI() {
    setState(() {
      isElement = false;
      filteredProcedure.clear();
      filteredProcedure.add(demarche1);
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

  html.window.addEventListener('contextmenu', (html.Event event) {
    event.preventDefault();
  });

    return Scaffold(
      body: Column(
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
                    'Aides aux démarches',
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
                padding: const EdgeInsets.all(8.0),
                child: filteredProcedure.isEmpty // Si aucune démarche n'est trouvé dans la recherche 
                    ? Text(
                        "Aucune démarche trouvée",
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      )
                    : Text(
                        "Démarches fréquemment utilisées",
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
              ),
          Expanded(
  child: GridView.builder(
    padding: const EdgeInsets.all(16.0),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: (MediaQuery.of(context).size.width / 330).floor(),
      crossAxisSpacing: 20.0,
      mainAxisSpacing: 20.0,
      childAspectRatio: 3, // Increase this number to make the tiles wider
    ),
    itemCount: filteredProcedure.length, // Adjust to your number of buttons
    itemBuilder: (context, index) {
      return Container(
        margin: const EdgeInsets.all(4.0), // Margin around the button for spacing
        decoration: BoxDecoration(
          color: Colors.white, // Background color of the button
          border: Border.all(color: const Color.fromRGBO(158, 158, 158, 1)), // Border color
          borderRadius: BorderRadius.circular(8.0), // Rounded corners
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DemarcheSelectedInterface(demarche: demarche1,)), // Retour à la page d'accueil
                    );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, // Background color (transparent to show Container color)
            disabledForegroundColor : Colors.grey, // Color for disabled button
            shadowColor: Colors.transparent, // No shadow
            elevation: 0, // Remove shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // Rounded corners to match Container
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0), // Padding inside the button
          ),
          child: Text(
            filteredProcedure[index].name, // The text inside the button
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorSettings.backgroundColor, // Text color
              fontWeight: FontWeight.bold, // Bold text
              fontSize: 16, // Text size
            ),
          ),
        ),
      );
    },
  ),
),


          MyFooter(), // Affiche le footer
        ],
      ),
    );
  }
}
