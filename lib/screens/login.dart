import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/screens.dart';
import '../widgets/widgets.dart';
import '../ctrls/api_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final url = TextEditingController();
    final ip = TextEditingController();
    final name = TextEditingController();
    // final login = TextEditingController();
    // final password = TextEditingController();
    ApiService apiService = Get.find();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Icon(Icons.key),
                const SizedBox(height: 8),
                Text(
                  "Приложение кассира",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                MyInputWidget(
                  inputName: 'веб-адрес приложения кассира, c https',
                  textEditingController: url,
                ),
                // MyInputWidget(
                //   inputName: "логин от сайта",
                //   textEditingController: login,
                // ),
                // MyInputWidget(
                //   inputName: "пароль от сайта",
                //   textEditingController: password,
                // ),
                MyInputWidget(
                  inputName: "ip адрес терминала",
                  textEditingController: ip,
                ),
                MyInputWidget(
                  inputName: "введите имя для приложения",
                  textEditingController: name,
                ),
                MyButtonWidget(
                  textButton: "Продолжить",
                  fn: () async {
                    if (url.text.isNotEmpty &&
                        ip.text.isNotEmpty &&
                        name.text.isNotEmpty 
                        //&&
                        // login.text.isNotEmpty &&
                       // password.text.isNotEmpty) {
                    ) {
                      if (await apiService.obtainToken(
                        name.text,
                        ip.text,
                        url.text
                       // login.text,
                      //  password.text,
                      )) {
                        Get.offAll(() => const LoadingPage());
                      }
                    } else {
                      Get.snackbar("Ошибка", "Все поля обязательные");
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
