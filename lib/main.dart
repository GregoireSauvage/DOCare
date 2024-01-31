import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:docare/user.dart';
import 'package:docare/document.dart';
import 'package:docare/doc_mobile.dart' // par defaut charge la version mobile
    if (dart.library.html) 'package:docare/doc_web.dart'; // sinon charge la version web

import 'package:provider/provider.dart'; // Pour utiliser le provider
import 'package:docare/user.dart'; // Pour utiliser la classe User
import 'package:docare/document.dart'; // Pour utiliser la classe Document
import 'package:docare/folder.dart'; // Pour utiliser la classe Folder

import 'package:docare/context_menu_mobile.dart'  // Charge la version mobile (dummy)
  if(dart.library.html) 'package:docare/context_menu.dart'; // Pour utiliser la classe MenuActions

void main() {
  
  // Create user
  User currentUser = User(
    userId: 1,
    username: 'Lucas',
    email: 'lucas@example.com',
    passwordHash: 'password',
    folderList: [],
  );

  Folder root = Folder( // Dossier racine
    id: 0,
    name: 'home',
    parentId: -1, // pas de dossier parent (dossier racine)
    folders: [],
    files: [],
    owner: currentUser, // utilisateur propriétaire du dossier (automatiquement ajouté à la liste des dossiers de l'utilisateur)
    sharedWith: [],
  );

  Document CNI = Document(
    id: 1,
    title: "Carte d'identité",
    fileType: 'img',
    path: 'assets/documents/CNI_example.png',
    creationDate: DateTime.now(),
    ownerId: currentUser.userId, // id de l'utilisateur propriétaire du document
    folder: currentUser.folderList[0], // dossier racine
  );
  Document annaleIAM = Document(
    id: 1,
    title: "annale d'IAM",
    fileType: 'pdf',
    path: 'assets/documents/iam_DS-3.pdf',
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
      ChangeNotifierProvider<User>(create: (context) => currentUser), // Existing user provider
      ChangeNotifierProvider<MenuActions>(create: (context) => MenuActions()), // Additional MenuActions provider
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

            // Bouton pour la page 2 //
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Ajouter la page 2
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
