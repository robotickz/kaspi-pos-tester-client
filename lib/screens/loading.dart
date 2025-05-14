import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ctrls/ctrls.dart';
import 'screens.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    Future.microtask(() => enterOrLogin());
    super.initState();
  }

  Future<void> enterOrLogin() async {
    ApiService apiService = Get.find();
    if (apiService.isAnyKeyInStorage()) {
      // if (await apiService.isTokenValid()) {
      //   Get.offAll(HomePage());
      // } else {
      //   Get.offAll(LoadingPage());
      // }
      Get.offAll(() => HomePage());
    } else {
      Get.offAll(() => LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
