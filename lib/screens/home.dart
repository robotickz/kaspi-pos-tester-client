import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../widgets/widgets.dart';
import '../ctrls/api_service.dart';
import 'screens.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    ApiService apiService = Get.find();
    final box = GetStorage("MyStorage");
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            MyButtonWidget(
              textButton: "Тест оплаты 10 тенге",
              fn: () async {
                await apiService.startPayment(1, 10, "fdf");

                int maxAttempts = 60; // 1 minute at 1-second intervals
                for (int i = 0; i < maxAttempts; i++) {
                  await Future.delayed(Duration(seconds: 1));
                  await apiService.checkStatus();

                  if (apiService.currentStatus.value !=
                      TransactionStatus.wait) {
                    break;
                  }
                }
              },
            ),
            MyButtonWidget(
              textButton: "Проверка статуса",
              fn: () {
                apiService.checkStatus();
              },
            ),
            MyButtonWidget(
              textButton: "Тест возврата 10 тенге",
              fn: () async {
                if (apiService.currentTransactionId.value.isNotEmpty) {
                  apiService.startRefund(
                    apiService.currentAmount.value,
                    apiService.currentTransactionId.value,
                    apiService.currentMethod.value,
                  );
                } else {
                  final transactionData = box.read('lastTransaction');

                  if (transactionData != null &&
                      transactionData['transactionId'] != null &&
                      transactionData['transactionId'].isNotEmpty) {
                    // Convert the method index back to enum
                    final methodIndex = transactionData['method'] ?? 0;
                    final method = TransactionMethod.values[methodIndex];

                    apiService.startRefund(
                      transactionData['amount'],
                      transactionData['transactionId'],
                      method,
                    );
                  } else {
                    Get.snackbar(
                      'Ошибка',
                      'Нет данных о транзакции для возврата',
                      duration: Duration(seconds: 5),
                    );
                  }
                }
              },
            ),
            MyButtonWidget(
              textButton: "Обновить токен",
              fn: () {
                apiService.revokeToken();
              },
            ),
            MyButtonWidget(
              textButton: "Информация об устройстве",
              fn: () {
                apiService.getDeviceInfo();
              },
            ),
            MyButtonWidget(
              textButton: "Очистка транзакций",
              fn: () {
                apiService.clearAllTransactions();
              },
            ),
            MyButtonWidget(
              textButton: "Проверка вебвью",
              fn: () {
                Get.to(
                  WebViewPage()
                );
              },
            ),
            MyButtonWidget(
              textButton: "Выход из приложения",
              fn: () {
                apiService.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
