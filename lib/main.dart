import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docare/user.dart';
import 'package:docare/document.dart';
import 'package:docare/doc_mobile.dart' // par defaut charge la version mobile
    if (dart.library.html) 'package:docare/doc_web.dart'; // sinon charge la version web

import 'package:docare/demarche_mobile.dart'
    if (dart.library.html) 'package:docare/demarche_web.dart';

import 'package:docare/folder.dart'; // Pour utiliser la classe Folder
import 'package:flutter/foundation.dart';

import 'package:docare/context_menu_mobile.dart' // Charge la version mobile (dummy)
    if (dart.library.html) 'package:docare/context_menu.dart'; // Pour utiliser la classe MenuActions

import 'package:cunning_document_scanner/cunning_document_scanner.dart'; // Pour scanner un document
import 'package:docare/scanner_UI_mobile.dart'; // Charge la version mobile (dummy)
import 'package:docare/font_size.dart'; // Pour utiliser la classe FontSizeSettings
import 'package:file_picker/file_picker.dart'; // Pour sélectionner un fichier
import 'dart:typed_data'; // Pour convertir un fichier en bytes

void main() {
  // Create user
  User currentUser = User(
    userId: 1,
    username: 'Lucas',
    email: 'lucas@example.com',
    passwordHash: 'password',
    folderList: [],
  );

  Folder root = Folder(
    // Dossier racine
    id: 0,
    name: 'home',
    parentId: -1, // pas de dossier parent (dossier racine)
    folders: [],
    files: [],
    owner:
        currentUser, // utilisateur propriétaire du dossier (automatiquement ajouté à la liste des dossiers de l'utilisateur)
    sharedWith: [],
  );

  Document CNI = Document(
    id: 1,
    title: "Carte d'identité",
    fileType: 'img',
    path: 'assets/documents/CNI_example.png',
    tags: ["document d'identités"],
    creationDate: DateTime.now(),
    ownerId: currentUser.userId, // id de l'utilisateur propriétaire du document
    folder: currentUser.folderList[0], // dossier racine
  );
  Document annaleIAM = Document(
    id: 1,
    title: "annale d'IAM",
    fileType: 'pdf',
    path: 'assets/documents/iam_DS-3.pdf',
    tags: ["personnel"],
    creationDate: DateTime.now(),
    ownerId: currentUser.userId, // id de l'utilisateur propriétaire du document
    folder: currentUser.folderList[0], // dossier racine
  );

  Folder folder1 = Folder(
    id: 1,
    name: 'Dossier 1',
    parentId: 0, // dossier parent = racine (automatiquement ajouté au parent)
    folders: [],
    files: [],
    owner: currentUser,
    sharedWith: [],
  );
  folder1.addFile(CNI); // Ajout du document CNI au dossier 1

  Folder folder2 = Folder(
    id: 2,
    name: 'Dossier 2',
    parentId: 1, // dossier parent = racine (automatiquement ajouté au parent)
    folders: [],
    files: [],
    owner: currentUser,
    sharedWith: [],
  );
  folder2.addFile(annaleIAM); // Ajout du document annaleIAM au dossier 2

  Folder examensMedicaux = Folder(
    id: 3,
    name: 'Examens médicaux',
    parentId: 0, // dossier parent = racine (automatiquement ajouté au parent)
    folders: [],
    files: [],
    owner: currentUser,
    sharedWith: [],
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<User>(
            create: (context) => currentUser), // Existing user provider
        ChangeNotifierProvider<MenuActions>(
            create: (context) =>
                MenuActions()), // Additional MenuActions provider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Constructeur

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOCare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'DOCare Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color.fromARGB(255, 53, 0, 243), Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 30.0), // Adjust the top padding as needed
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Réglages de la police'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                                'Taille actuelle de la police: ${FontSizeSettings.fontSize}'),
                            Slider(
                              value: FontSizeSettings.fontSize,
                              min: 10,
                              max: 30,
                              divisions: 20,
                              label:
                                  FontSizeSettings.fontSize.round().toString(),
                              onChanged: (value) {
                                setState(() {
                                  FontSizeSettings.setFontSize(value);
                                });
                              },
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Fermer'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.settings,
                        size: 34), // Utilise une icône de rouage
                    SizedBox(
                        width:
                            10), // Espaceur horizontal pour séparer l'icône du texte
                    // Ajouter ici le texte ou d'autres widgets si nécessaire
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),
            Image.asset(
              'assets/images/docare_logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const Text('Bienvenue sur DOCare !',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('Votre application tri administratif intelligent',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const Spacer(flex: 4),

            // Bouton pour la page 1 //
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DocumentInterface()),
                  );
                },
                // style pour le bouton "Mes documents"
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Couleur de fond du bouton
                  foregroundColor: const Color.fromARGB(
                      255, 53, 0, 243), // Couleur du texte du bouton
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 17),
                ),
                child:
                    const Text('Mes documents', style: TextStyle(fontSize: 20)),
              ),
            ),
            // Espacement entre les boutons //
            const SizedBox(height: 20),

            // Bouton pour ajouter un document //
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  if (kIsWeb) {
                    newDocumentWeb();
                  } else {
                    // ouvre une pop pup pour demander si l'utilisateur veut ajouter un document
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Ajouter un document'),
                          content: const Text(
                              'Voulez-vous scanner ou importer un document ?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // ferme la pop up
                                // Code to run only on mobile platforms
                                newDocumentMobile();
                              },
                              child: const Text('Importer'),
                            ),
                            TextButton(
                              onPressed: () async {
                                
                                List<String> pictures =
                                    await CunningDocumentScanner.getPictures(
                                            true) ??
                                        [];
                                if (pictures.isNotEmpty && mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DocumentScannerUI(pictures: pictures),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Scanner'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // ferme la pop up
                              },
                              child: const Text('Annuler'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                // style pour le bouton
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Couleur de fond du bouton
                  foregroundColor: const Color.fromARGB(
                      255, 53, 0, 243), // Couleur du texte du bouton
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 17),
                ),
                child: const Text('Ajouter un document',
                    style: TextStyle(fontSize: 20)),
              ),
            ),
            // Espacement entre les boutons //
            const SizedBox(height: 20),

            // Bouton pour la page 2 //
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DemarcheInterface()),
                  );
                },
                // style pour le bouton "Mes démarches"
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Couleur de fond du bouton
                  foregroundColor: const Color.fromARGB(
                      255, 53, 0, 243), // Couleur du texte du bouton
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 17),
                ),
                child:
                    const Text('Mes démarches', style: TextStyle(fontSize: 20)),
              ),
            ),

            const Spacer(flex: 2)
          ],
        ),
      ),
    );
  }
}

void newDocumentMobile() async {
  // async pour pouvoir utiliser await
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
      print('Type de fichier non supporté pour la visualisation directe.');
    }
  } else {
    // L'utilisateur a annulé la sélection de fichier
    print('Aucun fichier sélectionné.');
  }
}

void newDocumentWeb() async {
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
    } else if (file.extension == 'pdf') {
      PlatformFile file = result.files.first; // Récupérer le fichier
      // traiter la nouvelle image
    } else {
      // L'utilisateur a annulé la sélection de fichier
      print('Aucun fichier sélectionné.');
    }
  }
}
