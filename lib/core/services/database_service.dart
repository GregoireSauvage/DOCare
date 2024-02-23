import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:docare/features/document/document.dart';
import 'package:docare/core/models/folder.dart';
import 'package:docare/core/models/user.dart';

const String DOCUMENT_COLLECTION_REF = "documents"; 
const String FOLDER_COLLECTION_REF = "folders"; 

class DatabaseService{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _documentsRef;
  late final CollectionReference _foldersRef;

  Stream<List<Document_BDD>> getDocuments() {
    return _firestore.collection('documents').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Document_BDD.fromJason(doc.data() as Map<String, dynamic>)).toList();
    });

  }

  Stream<List<Folder_BDD>> getFolders() {
  return _firestore.collection('folders').snapshots().map((snapshot) {
    return snapshot.docs.map((folder) => Folder_BDD.fromJason(folder.data())).toList();
  });
}

Future<Folder?> getFolderByDocumentId(int documentId) async {
    try {
      // Retrieve the document with the specified ID
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(DOCUMENT_COLLECTION_REF).doc(documentId.toString()).get();

      // Retrieve folderId from the document
      int folderId = documentSnapshot['folderId'] as int;

      // Retrieve the folder with the same ID as folderId
      DocumentSnapshot folderSnapshot = await _foldersRef.doc(folderId.toString()).get();

      // If folder doesn't exist, return null
      if (!folderSnapshot.exists) {
        return null;
      }

      // Convert folder snapshot to a Folder object
      Folder folder = Folder(
        id: folderSnapshot['id'] as int,
        name: folderSnapshot['name'] as String,
        parentId: folderSnapshot['parentId'] as int,
        folders: [], // Assuming you don't retrieve subfolders here
        files: [], // Assuming you don't retrieve files here
        owner: User(userId: 1, username: "greg",email: "greg@", passwordHash: "azertyuiop", folderList: []), // Example, replace with actual owner data
      );
      print(folder);
      return folder;
    } catch (error) {
      // Handle errors if any
      print('Error retrieving folder: $error');
      return null;
    }
  }

DatabaseService() {
    _foldersRef = _firestore.collection(FOLDER_COLLECTION_REF);
    _documentsRef = _firestore.collection(DOCUMENT_COLLECTION_REF).withConverter<Document_BDD>(
      fromFirestore: (snapshots, _) => Document_BDD.fromJason(
        snapshots.data()!,
      ),
      toFirestore: (document, _) => document.toJson());
  }

  void initBDD() {
  // Create a local list to hold the documents
  List<Document_BDD> documents = [];

  // Listen to the stream of documents from Firestore
  DatabaseService().getDocuments().listen((event) {
    // If the event contains documents, set your local list to the new list of documents
    if (event.isNotEmpty) {
      documents = event;
      print(documents.length);

      // Here you would likely update your state with setState() if this is a stateful widget
      // For example:
      // setState(() {
      //   _myDocuments = documents;
      // });
    }
  }, onError: (error) {
    // Handle any errors here
    print(error);
  });
  }

  // DatabaseService() {
  //   _documentsRef = _firestore.collection(DOCUMENT_COLLECTION_REF).withConverter<Document_BDD>(
  //     fromFirestore: (snapshots, _) => Document_BDD.fromJason(
  //       snapshots.data()!,
  //     ),
  //     toFirestore: (document, _) => document.toJson());
  // }

  Stream<QuerySnapshot> getdocument() {
    return _documentsRef.snapshots();
  }

  void addDocument(Document document) async {
    print(document);
    _documentsRef.add(document);
  }

  void addDocument_bdd(Document_BDD document) async {
    print(document);
    _documentsRef.add(document);
  }

  void updateDocument(String documentId, Document document) {
    _documentsRef.doc(documentId).update(document.toJson());
  }

  void deleteDocument(String documentId) {
    _documentsRef.doc(documentId).delete();
  }

  
}