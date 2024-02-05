import 'package:flutter/material.dart';
import 'package:docare/main.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Pour charger un fichier depuis les assets
import 'package:provider/provider.dart'; // Pour utiliser le provider
import 'package:docare/user.dart'; // Classe User
import 'package:docare/folder.dart'; // Classe Folder

import 'package:flutter/foundation.dart';
import 'package:docare/hyperlink.dart'; // Pour afficher un lien hypertexte
import 'package:docare/footer_web.dart'; // Pour afficher le footer

import 'package:docare/demarche.dart'; // Pour les demarches administratives

class DemarcheSelectedInterface extends StatefulWidget {

  final Demarche demarche;

  DemarcheSelectedInterface({Key? key, required this.demarche}); // Constructeur

  @override
  _DemarcheSelectedInterfaceState createState() => _DemarcheSelectedInterfaceState();
}

class _DemarcheSelectedInterfaceState extends State<DemarcheSelectedInterface> {
  
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
                  sharedWith: [],
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

  TextEditingController searchController = TextEditingController(); // Contrôleur pour la barre de recherche
  List<Demarche> filteredProcedure = []; // Liste des démarches filtrés
  int idFolder = 0; // Index du dossier actuel - 0 = /home (ou root)
  int indexFolder = 0;
  

  @override
  void initState() {
    // Méthode appelée au démarrage de l'application
    super.initState();

    filteredProcedure.clear(); // Vide la liste des démarches
    // Ajoute les démarches de la liste de l'utilisateur à filteredProcedure
    filteredProcedure.add(widget.demarche);
  }


  // Callback function to update UI
  void updateUI() {
    setState(() {
      isElement = false;
      filteredProcedure.clear();
      filteredProcedure.add(widget.demarche);
    });
  }

  bool isElement = false; // True if the context menu is opened on an element (folder or document) - False if the context menu is opened on the background

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
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 30.0, bottom: 6.0, right: 30.0),
            child: Text(
              widget.demarche.description, // Description de la démarche
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30.0, bottom: 20.0),
            child: Hyperlink(widget.demarche.lien, widget.demarche.name), // Lien hypertexte pour la démarche

          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Documents à fournir pour compléter la démarche", style: TextStyle(fontSize: 20, color: Colors.grey))
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
              itemCount: widget.demarche.documentsNecessaires.length, // Adjust to your number of buttons
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
                      // Action when the button is pressed
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
                      widget.demarche.documentsNecessaires[index], // The text inside the button
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.blue, // Text color
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
