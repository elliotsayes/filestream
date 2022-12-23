// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:arweave/arweave.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

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

  String transactionId = '';
  Stream<TransactionUploader> uploadStatus = Stream.empty();

  Future<void> _openUploadFile(BuildContext context) async {
    final navigator = Navigator.of(context);

    const XTypeGroup typeGroup = XTypeGroup(
      label: 'file',
    );
    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    
    if (file == null) {
      return;
    }
    final String fileName = file.name;
    final String filePath = file.path;
    final int dataSize = await file.length();

    final transaction = await client.transactions.prepare(
      TransactionStream.withBlobData(dataStreamGenerator: file.openRead, dataSize: dataSize),
      widget.wallet,
    )
      ..addTag('file-name', fileName)
      ..addTag('upload-sdk', 'arweave-dart')
      ..addTag('upload-method', 'transaction-stream');
    await transaction.sign(widget.wallet);

    final uploadResult = client.transactions.upload(transaction);
    setState(() {
      transactionId = transaction.id;
      uploadStatus = uploadResult;
    });
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
            SelectableText(transactionId),
            StreamBuilder(
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data;
                  if (data == null) {
                    return const Text('Empty data');
                  }
                  final statusText = 'Uploading: ${data.uploadedChunks} / ${data.totalChunks} (${data.progress * 100}%)';
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
