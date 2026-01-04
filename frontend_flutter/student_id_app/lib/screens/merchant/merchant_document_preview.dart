import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class MerchantDocumentPreview extends StatelessWidget {
  final File file;

  const MerchantDocumentPreview({super.key, required this.file});

  bool get isImage =>
      file.path.endsWith('.jpg') ||
      file.path.endsWith('.jpeg') ||
      file.path.endsWith('.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Document Preview")),
      body: Center(
        child: isImage
            ? Image.file(file, fit: BoxFit.contain)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(file.path.split('/').last),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => OpenFilex.open(file.path),
                    child: const Text("Open PDF"),
                  )
                ],
              ),
      ),
    );
  }
}
