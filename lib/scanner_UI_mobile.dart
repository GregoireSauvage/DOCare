import 'dart:io';
import 'package:docare/document.dart';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:docare/user.dart';

class DocumentScannerUI extends StatefulWidget {
  final List<String> pictures;

  DocumentScannerUI({required this.pictures});

  @override
  _DocumentScannerUIState createState() => _DocumentScannerUIState();
}

class _DocumentScannerUIState extends State<DocumentScannerUI> {
  String _prediction = "";
  List _subcategoryPrediction = [];
  List<Document> _documents = [];

  @override
  void initState() {
    super.initState();
    if (widget.pictures.isNotEmpty) {
      classifyImage(); // Call the ML model prediction function
    }
    _initializeDocuments();
  }

  void _initializeDocuments() {
    _documents = List.generate(
      widget.pictures.length,
      (index) => Document.simpleConstructor(
        id: index,
        title: 'Document $index',
        fileType: 'img',
        path: widget.pictures[index],
        tags: [_subcategoryPrediction.toString()],
        ownerId: -1,
        folder: Provider.of<User>(context, listen: false).folderList[0],
      ),
    );
  }

  Future<void> _updateDocument(
      int index, String newName, List<String> newTags) async {
    setState(() {
      _documents[index].rename(newName);
      _documents[index].modifyTag(newTags);
    });
  }

  // ML model prediction result
  Future<void> classifyImage() async {
    
    File image = File(widget.pictures[0]);

    final url = Uri.parse('http://192.168.1.15:5000/predict');
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var jsonResponse = await response.stream.bytesToString();
        var decodedResponse = json.decode(jsonResponse);
        setState(() {
          _prediction = decodedResponse['predicted_class'];
          _subcategoryPrediction = decodedResponse['subcategory_prediction'];
          _initializeDocuments();
        });
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending request: $error');
    }
  }

  Future<void> _showEditDialog(BuildContext context, int documentIndex) async {
    Document document = _documents[documentIndex];
    TextEditingController nameController =
        TextEditingController(text: document.name);
    TextEditingController tagController =
        TextEditingController(text: document.tags.join(','));

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Modifier l'image"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                TextField(
                  controller: tagController,
                  decoration: const InputDecoration(
                    labelText: 'Tag',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Enregistrer'),
              onPressed: () {
                List<String> tags = tagController.text.split(',');
                _updateDocument(document.id, nameController.text, tags);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents Scannés'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                bottom: 10.0), // Leave space for the button
            child: widget.pictures.isEmpty
                ? Center(child: Text('Aucun document scanné.'))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                    ),
                    itemCount: widget.pictures.length,
                    itemBuilder: (context, index) {
                      // Your GridTile builder code
                      return GestureDetector(
                        onTap: () => _showEditDialog(context, index),
                        child: GridTile(
                          footer: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            color: Colors.black54,
                            child: Text(
                              _documents[index].name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          child: Image.file(File(_documents[index].path),
                              fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
          ),
          Positioned(
            bottom: 50.0,
            left: 26.0,
            right: 26.0,
            child: ElevatedButton(
              onPressed: () {
                for (int i = 0; i < _documents.length; i++) {
                  _documents[i].modifyOwner(
                      Provider.of<User>(context, listen: false).userId);
                  Provider.of<User>(context, listen: false)
                      .folderList[0]
                      .addFile(_documents[i]);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Button color
                foregroundColor: Colors.white, // Text color
                padding: const EdgeInsets.symmetric(
                    horizontal: 50, vertical: 20), // Button padding
                textStyle: const TextStyle(fontSize: 20), // Text style
              ),
              child: const Text('Valider'),
            ),
          ),
        ],
      ),
    );
  }
}
