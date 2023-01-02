// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
import 'dart:typed_data';

import 'package:arweave/arweave.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

/// Home Page of the application
class UploadPage extends StatefulWidget {
  final Wallet wallet;

  /// Default Constructor
  UploadPage({Key? key, required this.wallet}) : super(key: key);

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final Arweave client = Arweave();

  String statusText = 'Waiting for file';
  String transactionId = '';
  Stream<TransactionUploader> uploadStatus = Stream.empty();

  Future<void> _openUploadFile(BuildContext context) async {
    final navigator = Navigator.of(context);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: false,
        withReadStream: true,
      );

      if (result?.files.length != 1) {
        setState(() {
          statusText = 'No file selected';
        });
        return;
      }

      final file = result!.files.first;
      final fileName = file.name;
      final dataSize = file.size;

      if (file.readStream == null) {
        setState(() {
          statusText = 'File is not streamable';
        });
        return;
      }

      Stream<Uint8List> dataStreamGenerator([int? s, int? e]) {
        return file.readStream!(s, e).asyncMap((chunk) => chunk as Uint8List);
      }

      setState(() {
        statusText = 'Preparing transaction for $fileName ($dataSize bytes)';
      });
      final transaction = await client.transactions.prepare(
        TransactionStream.withBlobData(dataStreamGenerator: dataStreamGenerator, dataSize: dataSize),
        widget.wallet,
      );

      setState(() {
        statusText = 'Tagging transaction for $fileName ($dataSize bytes)';
      });
      transaction
        ..addTag('file-name', fileName)
        ..addTag('upload-sdk', 'arweave-dart')
        ..addTag('upload-method', 'transaction-stream');

      final mime = lookupMimeType(fileName);
      if (mime != null)  transaction.addTag('Content-Type', mime);

      setState(() {
        statusText = 'Signing transaction for $fileName ($dataSize bytes)';
      });
      await transaction.sign(widget.wallet);

      setState(() {
        statusText = 'Uploading transaction for $fileName ($dataSize bytes)';
      });
      final uploadResult = client.transactions.upload(transaction);
      setState(() {
        transactionId = transaction.id;
        uploadStatus = uploadResult;
      });
    } catch (e) {
      print(e);
      // setState(() {
      //   statusText = 'Error: $e';
      // });
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arweave Dart Stream Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Select File to upload'),
              onPressed: () => _openUploadFile(context),
            ),
            Text(statusText),
            SelectableText(transactionId),
            StreamBuilder(
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data;
                  if (data == null) {
                    return const Text('Empty data');
                  }
                  final statusText = 'Uploading: ${data.uploadedChunks} / ${data.totalChunks} (${data.progress * 100}%) ${data.isComplete ? 'Complete' : '...'}';
                  return Text(statusText);
                } else {
                  return const Text('No data');
                }
              },
              stream: uploadStatus,
            ),
          ],
        ),
      ),
    );
  }
}
