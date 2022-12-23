// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:arweave/arweave.dart';
import 'package:file_selector/file_selector.dart';
import 'package:filestream/upload_page.dart';
import 'package:flutter/material.dart';

/// Home Page of the application
class HomePage extends StatelessWidget {
  /// Default Constructor
  const HomePage({Key? key}) : super(key: key);

  Future<void> _openWalletFile(BuildContext context) async {
    final navigator = Navigator.of(context);

    const XTypeGroup typeGroup = XTypeGroup(
      label: 'wallets',
      extensions: <String>['json'],
    );
    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    
    if (file == null) {
      return;
    }
    // final String fileName = file.name;
    // final String filePath = file.path;
    final String walletString = await file.readAsString();
    final Wallet wallet = Wallet.fromJwk(jsonDecode(walletString));

    await navigator.push(
      MaterialPageRoute(
        builder: (context) => UploadPage(wallet: wallet),
      ),
    );
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
              child: const Text('Select Arweave Wallet File'),
              onPressed: () => _openWalletFile(context),
            ),
          ],
        ),
      ),
    );
  }
}
