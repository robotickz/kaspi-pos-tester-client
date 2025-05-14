import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';

import '../screens/screens.dart';
import 'provider.dart';

enum TransactionStatus { wait, success, fail, unknown }

enum TransactionMethod { qr, card }

enum TransactionSubStatus {
  initialize,
  waitUser,
  waitForQrConfirmation,
  processingCard,
  waitForPinCode,
  processRefund,
  qrTransactionSuccess,
  qrTransactionFailure,
  cardTransactionSuccess,
  cardTransactionFailure,
  processCancelled,
}

final box = GetStorage('MyStorage');

class ApiService extends GetxController {
  DateTime currentDate = DateTime.now();
  String? accessToken = box.read('accessToken');
  String? refreshToken = box.read('refreshToken');
  DateTime? expirationDate;
  String? ipAddress = box.read('ip');
  String? appName = box.read('name');
  String? urlAddress = box.read('url');

  // Current transaction tracking
  var isLoading = false.obs;
  var currentTransactionId = ''.obs;
  var currentProcessId = ''.obs;
  var currentStatus = TransactionStatus.wait.obs;
  var currentSubStatus = TransactionSubStatus.initialize.obs;
  var currentAmount = ''.obs;
  var currentMethod = TransactionMethod.qr.obs;
  var transactionMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (box.read('expirationDate') != null) {
      try {
        expirationDate = DateTime.parse(box.read('expirationDate'));
      } catch (e) {
        expirationDate = null;
      }
    }

    loadLastTransaction();
  }

  void loadLastTransaction() {
    if (box.hasData('lastTransaction')) {
      try {
        final data = box.read('lastTransaction');

        currentProcessId.value = data['processId'] ?? '';
        currentTransactionId.value = data['transactionId'] ?? '';
        currentAmount.value = data['amount'] ?? '';
        currentMethod.value = TransactionMethod.values[data['method'] ?? 0];
        currentStatus.value = TransactionStatus.values[data['status'] ?? 0];
        currentSubStatus.value =
            TransactionSubStatus.values[data['subStatus'] ?? 0];
        transactionMessage.value = data['message'] ?? '';

        // If there was a pending transaction, check its status
        if (currentStatus.value == TransactionStatus.wait &&
            currentProcessId.value.isNotEmpty) {}
      } catch (e) {
        Get.snackbar("Message", "Ошибка $e");
      }
    }
  }

  void saveLastTransaction() {
    final data = {
      'processId': currentProcessId.value,
      'transactionId': currentTransactionId.value,
      'amount': currentAmount.value,
      'method': currentMethod.value.index,
      'status': currentStatus.value.index,
      'subStatus': currentSubStatus.value.index,
      'message': transactionMessage.value,
      'timestamp': DateTime.now().toIso8601String(),
    };

    box.write('lastTransaction', data);
  }

  KaspiApiClient? _apiClient;
  KaspiApiClient get apiClient {
    if (_apiClient == null && ipAddress != null) {
      _apiClient = KaspiApiClient(ipAddress!);
    }
    if (_apiClient == null) {
      throw Exception("IP address not set");
    }
    return _apiClient!;
  }

  Future<bool> obtainToken(
    String name,
    String ip,
    String url,
    // String login,
    //  String password,
  ) async {
    isLoading.value = true;

    try {
      Get.snackbar(
        'Внимание',
        'Пожалуйста, примите запрос на терминале',
        duration: Duration(seconds: 10),
      );

      final client = KaspiApiClient(ip);

      final response = await client.register(name);

      if (response.statusCode != 200) {
        throw Exception(
          "Ошибка HTTP ${response.statusCode}: ${response.statusMessage}",
        );
      }

      if (response.data != null && response.data!.containsKey("errorText")) {
        throw Exception("Ошибка от терминала: ${response.data!["errorText"]}");
      }

      if (response.data != null &&
          response.data!.containsKey("data") &&
          response.data!["data"] != null &&
          response.data!["data"].containsKey("accessToken")) {
        box.write("accessToken", response.data!["data"]["accessToken"]);
        box.write("refreshToken", response.data!["data"]["refreshToken"]);
        box.write("expirationDate", response.data!["data"]["expirationDate"]);
        box.write("name", name);
        box.write("ip", ip);
        box.write("url", url);
        //  box.write("login", login);
        //  box.write("password", password);

        accessToken = response.data!["data"]["accessToken"];
        refreshToken = response.data!["data"]["refreshToken"];
        ipAddress = ip;
        appName = name;
        urlAddress = url;


        try {
          String expDateStr = response.data!["data"]["expirationDate"];
          if (expDateStr.contains(",")) {
            expirationDate = DateFormat(
              "MMM d, yyyy HH:mm:ss",
            ).parse(expDateStr);
          } else {
            expirationDate = DateFormat(
              "yyyy-MM-dd HH:mm:ss",
            ).parse(expDateStr);
          }
        } catch (e) {
          expirationDate = DateTime.now().add(Duration(hours: 23));
        }

        box.write("expirationDate", expirationDate!.toIso8601String());

        _apiClient = null;

        Get.snackbar(
          'Успешно',
          'Регистрация выполнена успешно',
          duration: Duration(seconds: 3),
        );

        isLoading.value = false;
        return true;
      } else {
        throw Exception("Неверный формат ответа");
      }
    } catch (e) {
      isLoading.value = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Ошибка',
          "Проверьте правильность IP адреса и примите запрос на терминале: ${e.toString()}",
          duration: Duration(seconds: 8),
        );
      });
      return false;
    }
  }

  Future<bool> revokeToken() async {
    if (refreshToken == null || ipAddress == null || appName == null) {
      Get.snackbar('Ошибка', 'Отсутствуют данные для обновления токена');
      return false;
    }

    try {
      final response = await apiClient.revokeToken(
        refreshToken!,
        appName!,
        accessToken!,
      );

      if (response.statusCode != 200) {
        throw Exception("Ошибка обновления токена");
      }

      if (response.data != null && response.data!.containsKey("errorText")) {
        throw Exception("Ошибка от терминала: ${response.data!["errorText"]}");
      }

      if (response.data != null && response.data!.containsKey("data")) {
        box.write("accessToken", response.data!["data"]["accessToken"]);
        box.write("refreshToken", response.data!["data"]["refreshToken"]);
        box.write("expirationDate", response.data!["data"]["expirationDate"]);

        accessToken = response.data!["data"]["accessToken"];
        refreshToken = response.data!["data"]["refreshToken"];

        try {
          String expDateStr = response.data!["data"]["expirationDate"];
          if (expDateStr.contains(",")) {
            expirationDate = DateFormat(
              "MMM d, yyyy HH:mm:ss",
            ).parse(expDateStr);
          } else {
            expirationDate = DateFormat(
              "yyyy-MM-dd HH:mm:ss",
            ).parse(expDateStr);
          }
        } catch (e) {
          expirationDate = DateTime.now().add(Duration(hours: 23));
        }

        box.write("expirationDate", expirationDate!.toIso8601String());

        return true;
      } else {
        throw Exception("Неверный формат ответа");
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Ошибка', "Не удалось обновить токен: ${e.toString()}");
      });
      return false;
    }
  }

  Future<bool> startPayment(int orderId, int amount, String token) async {
    if (accessToken == null || ipAddress == null) {
      Get.snackbar('Ошибка', 'Не авторизован. Выполните вход снова.');
      return false;
    }

    currentStatus.value = TransactionStatus.wait;
    currentSubStatus.value = TransactionSubStatus.initialize;
    currentProcessId.value = '';
    currentTransactionId.value = '';
    currentAmount.value = amount.toString();
    transactionMessage.value = '';

    try {
      isLoading.value = true;

      if (await isTokenValid()) {
        final response = await apiClient.payment(
          amount.toString(),
          accessToken!,
          ownCheque: true,
        );

        if (response.statusCode != 200) {
          throw Exception("Ошибка запроса оплаты");
        }

        if (response.data != null && response.data!.containsKey("errorText")) {
          throw Exception(
            "Ошибка от терминала: ${response.data!["errorText"]}",
          );
        }

        if (response.data != null &&
            response.data!.containsKey("data") &&
            response.data!["data"].containsKey("processId")) {
          currentProcessId.value = response.data!["data"]["processId"];

          saveLastTransaction();

          return true;
        } else {
          throw Exception("Неверный формат ответа");
        }
      } else {
        throw Exception("Токен не действителен");
      }
    } catch (e) {
      transactionMessage.value = e.toString();
      isLoading.value = false;

      currentStatus.value = TransactionStatus.fail;
      saveLastTransaction();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Ошибка оплаты',
          e.toString(),
          duration: Duration(seconds: 5),
        );
      });

      return false;
    }
  }

  Future<Map<String, dynamic>?> checkStatus() async {
    if (accessToken == null || currentProcessId.value.isEmpty) {
      return null;
    }

    try {
      final response = await apiClient.status(
        currentProcessId.value,
        accessToken!,
      );

      if (response.statusCode != 200) {
        throw Exception("Ошибка запроса статуса");
      }

      if (response.data != null && response.data!.containsKey("errorText")) {
        throw Exception("Ошибка от терминала: ${response.data!["errorText"]}");
      }

      if (response.data != null && response.data!.containsKey("data")) {
        final data = response.data!["data"];

        // Update status
        String status = data["status"];
        if (status == "wait") {
          currentStatus.value = TransactionStatus.wait;
        } else if (status == "success") {
          currentStatus.value = TransactionStatus.success;
          isLoading.value = false;
        } else if (status == "fail") {
          currentStatus.value = TransactionStatus.fail;
          isLoading.value = false;
        } else if (status == "unknown") {
          currentStatus.value = TransactionStatus.unknown;
        }

        if (data.containsKey("subStatus")) {
          String subStatus = data["subStatus"];

          if (subStatus == "Initialize") {
            currentSubStatus.value = TransactionSubStatus.initialize;
          } else if (subStatus == "WaitUser") {
            currentSubStatus.value = TransactionSubStatus.waitUser;
          } else if (subStatus == "WaitForQrConfirmation") {
            currentSubStatus.value = TransactionSubStatus.waitForQrConfirmation;
          } else if (subStatus == "ProcessingCard") {
            currentSubStatus.value = TransactionSubStatus.processingCard;
          } else if (subStatus == "WaitForPinCode") {
            currentSubStatus.value = TransactionSubStatus.waitForPinCode;
          } else if (subStatus == "ProcessRefund") {
            currentSubStatus.value = TransactionSubStatus.processRefund;
          } else if (subStatus == "QrTransactionSuccess") {
            currentSubStatus.value = TransactionSubStatus.qrTransactionSuccess;
            currentMethod.value = TransactionMethod.qr;
          } else if (subStatus == "QrTransactionFailure") {
            currentSubStatus.value = TransactionSubStatus.qrTransactionFailure;
            currentMethod.value = TransactionMethod.qr;
          } else if (subStatus == "CardTransactionSuccess") {
            currentSubStatus.value =
                TransactionSubStatus.cardTransactionSuccess;
            currentMethod.value = TransactionMethod.card;
          } else if (subStatus == "CardTransactionFailure") {
            currentSubStatus.value =
                TransactionSubStatus.cardTransactionFailure;
            currentMethod.value = TransactionMethod.card;
          } else if (subStatus == "ProcessCancelled") {
            currentSubStatus.value = TransactionSubStatus.processCancelled;
          }
        }

        if (currentStatus.value == TransactionStatus.success &&
            data.containsKey("transactionId")) {
          currentTransactionId.value = data["transactionId"];
          saveLastTransaction();
        }

        if ((currentStatus.value == TransactionStatus.fail ||
                currentStatus.value == TransactionStatus.unknown) &&
            data.containsKey("message")) {
          transactionMessage.value = data["message"];
        }

        return data;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> actualizeTransaction() async {
    if (accessToken == null || currentProcessId.value.isEmpty) {
      return false;
    }

    try {
      final response = await apiClient.actualize(
        currentProcessId.value,
        accessToken!,
      );

      if (response.statusCode != 200) {
        throw Exception("Ошибка запроса актуализации");
      }

      if (response.data != null && response.data!.containsKey("errorText")) {
        throw Exception("Ошибка от терминала: ${response.data!["errorText"]}");
      }

      if (response.data != null && response.data!.containsKey("data")) {
        final data = response.data!["data"];

        String status = data["status"];
        if (status == "wait") {
          currentStatus.value = TransactionStatus.wait;
        } else if (status == "success") {
          currentStatus.value = TransactionStatus.success;

          isLoading.value = false;
        } else if (status == "fail") {
          currentStatus.value = TransactionStatus.fail;
          isLoading.value = false;
        } else if (status == "unknown") {
          currentStatus.value = TransactionStatus.unknown;
        }

        if (data.containsKey("subStatus")) {
          String subStatus = data["subStatus"];

          if (subStatus == "Initialize") {
            currentSubStatus.value = TransactionSubStatus.initialize;
          } else if (subStatus == "WaitUser") {
            currentSubStatus.value = TransactionSubStatus.waitUser;
          } else if (subStatus == "WaitForQrConfirmation") {
            currentSubStatus.value = TransactionSubStatus.waitForQrConfirmation;
          } else if (subStatus == "ProcessingCard") {
            currentSubStatus.value = TransactionSubStatus.processingCard;
          } else if (subStatus == "WaitForPinCode") {
            currentSubStatus.value = TransactionSubStatus.waitForPinCode;
          } else if (subStatus == "ProcessRefund") {
            currentSubStatus.value = TransactionSubStatus.processRefund;
          } else if (subStatus == "QrTransactionSuccess") {
            currentSubStatus.value = TransactionSubStatus.qrTransactionSuccess;
            currentMethod.value = TransactionMethod.qr;
          } else if (subStatus == "QrTransactionFailure") {
            currentSubStatus.value = TransactionSubStatus.qrTransactionFailure;
            currentMethod.value = TransactionMethod.qr;
          } else if (subStatus == "CardTransactionSuccess") {
            currentSubStatus.value =
                TransactionSubStatus.cardTransactionSuccess;
            currentMethod.value = TransactionMethod.card;
          } else if (subStatus == "CardTransactionFailure") {
            currentSubStatus.value =
                TransactionSubStatus.cardTransactionFailure;
            currentMethod.value = TransactionMethod.card;
          } else if (subStatus == "ProcessCancelled") {
            currentSubStatus.value = TransactionSubStatus.processCancelled;
          }
        }

        if (currentStatus.value == TransactionStatus.success &&
            data.containsKey("transactionId")) {
          currentTransactionId.value = data["transactionId"];

          saveLastTransaction();
        }

        if ((currentStatus.value == TransactionStatus.fail ||
                currentStatus.value == TransactionStatus.unknown) &&
            data.containsKey("message")) {
          transactionMessage.value = data["message"];
        }

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startRefund(
    String amount,
    String transactionId,
    TransactionMethod method,
  ) async {
    if (accessToken == null || ipAddress == null) {
      Get.snackbar('Ошибка', 'Не авторизован. Выполните вход снова.');
      return false;
    }

    currentStatus.value = TransactionStatus.wait;
    currentSubStatus.value = TransactionSubStatus.initialize;
    currentProcessId.value = '';
    currentTransactionId.value = transactionId;
    currentAmount.value = amount;
    currentMethod.value = method;
    transactionMessage.value = '';

    try {
      isLoading.value = true;

      if (await isTokenValid()) {
        final methodStr = method == TransactionMethod.qr ? 'qr' : 'card';

        final response = await apiClient.refund(
          methodStr,
          amount,
          transactionId,
          accessToken!,
          ownCheque: true,
        );

        if (response.statusCode != 200) {
          throw Exception("Ошибка запроса возврата");
        }

        if (response.data != null && response.data!.containsKey("errorText")) {
          throw Exception(
            "Ошибка от терминала: ${response.data!["errorText"]}",
          );
        }

        if (response.data != null &&
            response.data!.containsKey("data") &&
            response.data!["data"].containsKey("processId")) {
          currentProcessId.value = response.data!["data"]["processId"];

          saveLastTransaction();

          return true;
        } else {
          throw Exception("Неверный формат ответа");
        }
      } else {
        throw Exception("Токен не действителен");
      }
    } catch (e) {
      transactionMessage.value = e.toString();
      isLoading.value = false;

      currentStatus.value = TransactionStatus.fail;
      saveLastTransaction();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Ошибка возврата',
          e.toString(),
          duration: Duration(seconds: 5),
        );
      });

      return false;
    }
  }

  Future<bool> recoverLastTransaction() async {
    if (currentProcessId.value.isEmpty ||
        currentStatus.value != TransactionStatus.wait) {
      return false;
    }

    final result = await checkStatus();

    if (result == null) {
      return false;
    }

    if (currentStatus.value == TransactionStatus.unknown) {
      return await actualizeTransaction();
    }

    return currentStatus.value == TransactionStatus.success;
  }

  void clearLastTransaction() {
    currentProcessId.value = '';
    currentTransactionId.value = '';
    currentAmount.value = '';
    currentStatus.value = TransactionStatus.wait;
    currentSubStatus.value = TransactionSubStatus.initialize;
    transactionMessage.value = '';

    if (box.hasData('lastTransaction')) {
      box.remove('lastTransaction');
    }
  }

  Future<Map<String, dynamic>?> getDeviceInfo() async {
    if (accessToken == null) {
      return null;
    }

    try {
      final response = await apiClient.deviceInfo(accessToken!);

      if (response.statusCode != 200) {
        throw Exception("Ошибка запроса информации об устройстве");
      }

      if (response.data != null && response.data!.containsKey("errorText")) {
        throw Exception("Ошибка от терминала: ${response.data!["errorText"]}");
      }

      if (response.data != null && response.data!.containsKey("data")) {
        return response.data!["data"];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isTokenValid() async {
    if (expirationDate == null) {
      return false;
    }

    if (expirationDate!.isAfter(currentDate.add(Duration(hours: 20)))) {
      return true;
    } else {
      if (await revokeToken()) {
        return true;
      } else {
        Get.snackbar("Ошибка", "Токен не обновился");
      }
    }
    return false;
  }

  bool isAnyKeyInStorage() {
    return accessToken != null &&
        refreshToken != null &&
        expirationDate != null;
  }

  bool isValidIpAddress(String ip) {
    RegExp ipRegex = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

    if (!ipRegex.hasMatch(ip)) {
      return false;
    }

    var parts = ip.split('.');
    for (var part in parts) {
      var intPart = int.parse(part);
      if (intPart < 0 || intPart > 255) {
        return false;
      }
    }

    return true;
  }

  String getStatusMessage() {
    if (currentStatus.value == TransactionStatus.wait) {
      switch (currentSubStatus.value) {
        case TransactionSubStatus.initialize:
          return "Инициализация...";
        case TransactionSubStatus.waitUser:
          return "Ожидание действий клиента...";
        case TransactionSubStatus.waitForQrConfirmation:
          return "Ожидание подтверждения QR...";
        case TransactionSubStatus.processingCard:
          return "Обработка карты...";
        case TransactionSubStatus.waitForPinCode:
          return "Ожидание ввода PIN-кода...";
        case TransactionSubStatus.processRefund:
          return "Обработка возврата...";
        default:
          return "Ожидание...";
      }
    } else if (currentStatus.value == TransactionStatus.success) {
      return "Успешно завершено";
    } else if (currentStatus.value == TransactionStatus.fail) {
      return transactionMessage.value.isNotEmpty
          ? "Ошибка: ${transactionMessage.value}"
          : "Операция не выполнена";
    } else if (currentStatus.value == TransactionStatus.unknown) {
      return transactionMessage.value.isNotEmpty
          ? "Неизвестный статус: ${transactionMessage.value}"
          : "Неизвестный статус операции";
    } else {
      return "Неизвестный статус";
    }
  }

  void clearAllTransactions() {
    apiClient.resetTransactions();
    Get.snackbar("Сообщение", "Транзакции очищены");
  }

  Future<bool> makePaymentComplete(String token, int id) async {
    final url = Uri.parse(
      'https://yourdomain/api/orders/complete_payment/$id',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        Get.snackbar("Ошибка", "Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      Get.snackbar("Ошибка", "Error making request: $e");
      return false;
    }
  }

  void logout() {
    box.remove('accessToken');
    box.remove('refreshToken');
    box.remove('expirationDate');
    box.remove('ip');
    box.remove('url');
    box.remove('name');
   // box.remove("login");
   // box.remove("password");
    clearLastTransaction();

    accessToken = null;
    refreshToken = null;
    expirationDate = null;
    ipAddress = null;
    appName = null;
    urlAddress = null;

    _apiClient = null;

    Get.offAll(() => const LoadingPage());
  }
}
