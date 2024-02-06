import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

class DocumentScannerUI extends StatefulWidget {
  final List<String> pictures;

  DocumentScannerUI({required this.pictures});

  @override
  _DocumentScannerUIState createState() => _DocumentScannerUIState();
}

class _DocumentScannerUIState extends State<DocumentScannerUI> {

  @override
  Widget build(BuildContext context) {
    // Utiliser widget.pictures pour accéder à la liste des images scannées
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents Scannés'),
      ),
      body: _buildGridView(),
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: widget.pictures.isEmpty
          ? Center(child: Text('Aucun document scanné.'))
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: widget.pictures.length,
              itemBuilder: (context, index) {
                String imagePath = widget.pictures[index];
                return GridTile(
                  child: Image.file(File(imagePath), fit: BoxFit.cover),
                );
              },
            ),
    );
  }
}
