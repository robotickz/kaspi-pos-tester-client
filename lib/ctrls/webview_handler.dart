import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'provider.dart';
import '../screens/screens.dart';

class WebViewHandler extends GetxController {
  final box = GetStorage('MyStorage');
  final isLoading = true.obs;
  final isError = false.obs;
  final errorMessage = ''.obs;
  final retryCount = 0.obs;
  final maxRetries = 5;

  final isRetrying = false.obs;

  late KaspiApiClient _apiClient;

  WebViewController? _webViewController;
  Timer? _retryTimer;
  Timer? _loadingTimeoutTimer;

  @override
  void onInit() {
    super.onInit();

    final ip = box.read<String>('ip') ?? '';
    if (ip.isNotEmpty) {
      _apiClient = KaspiApiClient(ip);
    }
  }

  @override
  void onClose() {
    _retryTimer?.cancel();
    _loadingTimeoutTimer?.cancel();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.onClose();
  }

  void _startLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(Duration(seconds: 10), () {
      if (isLoading.value) {
        isLoading.value = false;
      }
    });
  }

  void sendDataToWebView(dynamic data) {
    if (_webViewController != null) {
      try {
        final jsonData = jsonEncode(data);
        _webViewController!.runJavaScript("onFlutterMessage($jsonData)");
      } catch (e) {
        Get.snackbar('Error', 'Failed to send data to WebView: $e');
      }
    }
  }

  Future<void> openWebView(
    BuildContext context, {
    String? phone,
    String? password,
    String? extraPath,
  }) async {
    retryCount.value = 0;
    isRetrying.value = false;

    _retryTimer?.cancel();
    _loadingTimeoutTimer?.cancel();

    isLoading.value = true;
    isError.value = false;
    errorMessage.value = '';

    final url = box.read<String>('url');
    if (url == null || url.isEmpty) {
      isError.value = true;
      errorMessage.value = 'URL not found in storage';
      isLoading.value = false;
      Get.offAll(() => LoginPage());
      return;
    }

    final params = <String, String>{};
    if (phone?.isNotEmpty == true) params['email'] = phone!;
    if (password?.isNotEmpty == true) params['phone'] = password!;

    String query = '';
    if (params.isNotEmpty) {
      query = '?${Uri(queryParameters: params).query}';
    }

    if (extraPath?.isNotEmpty == true) {
      if (extraPath!.startsWith('?') || extraPath.startsWith('&')) {
        final sep = query.isEmpty ? '?' : '&';
        query += sep + extraPath.substring(1);
      } else {
        String validUrl =
            url.startsWith(RegExp(r'https?://')) ? url : 'https://$url';
        validUrl =
            validUrl + (extraPath.startsWith('/') ? extraPath : '/$extraPath');
        final fullUrl = validUrl + query;
        await _attemptLoadUrl(fullUrl);
        return;
      }
    }

    String validUrl =
        url.startsWith(RegExp(r'https?://')) ? url : 'https://$url';

    final fullUrl = validUrl + query;

    await _attemptLoadUrl(fullUrl);
  }

  Future<void> _attemptLoadUrl(String url) async {
    if (retryCount.value >= maxRetries) {
      isError.value = true;
      errorMessage.value = 'Failed to connect after $maxRetries attempts';
      isLoading.value = false;
      return;
    }

    _startLoadingTimeout();

    bool hasInternet = await _apiClient.testInternetConnection();
    if (!hasInternet) {
      _scheduleRetry(url);
      return;
    }

    try {
      _webViewController =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(const Color(0xFFFFFBE9))
            ..clearCache()
            ..clearLocalStorage()
            ..setUserAgent(
              'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
            )
            ..addJavaScriptChannel(
              'AndroidBridge',
              onMessageReceived: (JavaScriptMessage message) {
                openPaymentScreen(message.message);
                if (message.message == 'PAGE_LOADED') {
                  isLoading.value = false;
                }
              },
            );

      await _webViewController?.loadRequest(Uri.parse(url));

      Future.delayed(Duration(seconds: 3), () {
        if (isLoading.value) {
          isLoading.value = false;
        }
      });
    } catch (e) {
      if (!isRetrying.value && retryCount.value < maxRetries) {
        _scheduleRetry(url);
      } else if (retryCount.value >= maxRetries) {
        isError.value = true;
        errorMessage.value = 'Error loading WebView: $e';
        isLoading.value = false;
      }
    }
  }

  void _scheduleRetry(String url) {
    isRetrying.value = true;

    retryCount.value++;

    isError.value = true;
    errorMessage.value =
        'Соединение не удалось, пробую еще (${retryCount.value}/$maxRetries)...';

    _retryTimer?.cancel();

    final retryDelay = Duration(seconds: retryCount.value * 2);
    _retryTimer = Timer(retryDelay, () async {
      isRetrying.value = false;

      if (retryCount.value >= maxRetries) {
        isError.value = true;
        errorMessage.value = 'Failed to connect after $maxRetries attempts';
        isLoading.value = false;
        return;
      }

      bool hasInternet = await _apiClient.testInternetConnection();
      if (hasInternet) {
        isError.value = false;
        errorMessage.value = '';
        _attemptLoadUrl(url);
      } else if (retryCount.value < maxRetries) {
        _scheduleRetry(url);
      } else {
        isError.value = true;
        errorMessage.value = 'Failed to connect after $maxRetries attempts';
        isLoading.value = false;
      }
    });
  }

  void openPaymentScreen(String message) {
    try {
      Map<String, dynamic> paymentData = jsonDecode(message);

      Get.to(
        PaymentPage(
          orderId: paymentData['orderId'],
          amount: paymentData['totalAmount'],
          token: paymentData['accessToken'],
        ),
      );
    } catch (e) {
      Get.snackbar('Error', 'Error handling payment request: $e');
    }
  }

  WebViewController? get webViewController => _webViewController;

  void forceHideLoading() {
    isLoading.value = false;
  }
}
