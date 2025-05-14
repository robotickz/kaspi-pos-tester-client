import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'screens/screens.dart';
import 'ctrls/init.dart' as ic;

Future<void> main() async {
  await ic.init();
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cashier App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Nunito',
        useMaterial3: true,
      ),
      home: LoadingPage(),
    ),
  );
}
