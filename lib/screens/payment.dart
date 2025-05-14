import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ctrls/ctrls.dart';
import '../widgets/widgets.dart';
import '../screens/screens.dart';

class PaymentPage extends StatelessWidget {
  final int orderId;
  final int amount;
  final String token;

  const PaymentPage({
    super.key,
    required this.orderId,
    required this.amount,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    ApiService apiService = Get.find();
    return Scaffold(
      appBar: AppBar(title: Text('Native Payment')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Processing payment...'),
            Text('Order ID: $orderId'),
            Text('Amount: $amount KZT'),
            MyButtonWidget(
              textButton: "Оплатить",
              bg: Colors.green,
              fn: () async {
                await apiService.startPayment(orderId, amount, token);
                int maxAttempts = 60;
                Get.snackbar("Сообщение", "Ожидание оплаты");
                for (int i = 0; i < maxAttempts; i++) {
                  await Future.delayed(Duration(seconds: 1));
                  await apiService.checkStatus();
                  if (apiService.currentStatus.value ==
                      TransactionStatus.success) {
                    await apiService.makePaymentComplete(token, orderId);
                    Get.to(WebViewPage(extraPath: "/thanks"));
                    Future.delayed(Duration(seconds: 5), () {
                      Get.offAll(() => LoadingPage());
                    });
                    break;
                  }
                  if (apiService.currentStatus.value ==
                          TransactionStatus.fail ||
                      apiService.currentStatus.value ==
                          TransactionStatus.unknown) {
                    Get.snackbar(
                      "Ошибка",
                      "Оплата не удалась, попробуйте снова",
                    );
                    break;
                  }
                }
              },
            ),
            MyButtonWidget(
              textButton: "Отменить",
              fn: () {
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
