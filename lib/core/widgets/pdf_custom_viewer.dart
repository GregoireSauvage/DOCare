import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class CustomPDFViewerScreen extends StatelessWidget {
  final String filePath;
  final Function onChangeDocument;

  const CustomPDFViewerScreen({
    Key? key,
    required this.filePath,
    required this.onChangeDocument,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String fileName = filePath.split('/').last;
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: PDFView(
        filePath: filePath,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onChangeDocument(),
        child: Icon(Icons.change_circle),
        tooltip: 'Change Document',
      ),
    );
  }
}
