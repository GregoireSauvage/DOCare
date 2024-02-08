import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:docare/document.dart';


const String DOCUMENT_COLLECTION_REF = "documents"; 

class DatabaseService{
  final _firestore = FirebaseFirestore.instance;

  late final CollectionReference _documentsRef;

  DatabaseService() {
    _documentsRef = _firestore.collection(DOCUMENT_COLLECTION_REF).withConverter<Document_BDD>(
      fromFirestore: (snapshots, _) => Document_BDD.fromJason(
        snapshots.data()!,
      ),
      toFirestore: (document, _) => document.toJson());
  }

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