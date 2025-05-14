import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../ctrls/webview_handler.dart';

class WebViewPage extends StatefulWidget {
  final String? phone;
  final String? password;
  final String? extraPath;

  const WebViewPage({this.phone, this.password, this.extraPath, super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewHandler controller;
  bool pageInteracted = false;

  @override
  void initState() {
    super.initState();

    controller = Get.put(
      WebViewHandler(),
      tag: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.openWebView(
        context,
        phone: widget.phone,
        password: widget.password,
        extraPath: widget.extraPath,
      );

      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.top],
      );

      if (widget.phone != null &&
          widget.password != null &&
          widget.phone!.isNotEmpty &&
          widget.password!.isNotEmpty) {
        Future.delayed(Duration(seconds: 2), () {
          sendDataIfNeeded();
        });
      }
    });
  }

  void sendDataIfNeeded() {
    if (widget.phone != null &&
        widget.password != null &&
        widget.phone!.isNotEmpty &&
        widget.password!.isNotEmpty &&
        controller.webViewController != null) {
      try {
        Map<String, dynamic> data = {
          'phone': widget.phone,
          'password': widget.password,
        };

        controller.sendDataToWebView(data);
      } catch (e) {
        Get.snackbar("Error", "Error sending data: $e");
      }
    }
  }

  @override
  void dispose() {
    Get.delete<WebViewHandler>(tag: controller.toString());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.delete<WebViewHandler>(tag: controller.toString());
          Get.back();
        }
      },
      child: Scaffold(
        body: Obx(() {
          if (controller.isLoading.value &&
              controller.webViewController == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка...'),
                ],
              ),
            );
          } else if (controller.isError.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.signal_wifi_off,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () =>
                        controller.retryCount.value < controller.maxRetries
                            ? const Text('Повторное подключение...')
                            : ElevatedButton(
                              onPressed:
                                  () => controller.openWebView(
                                    context,
                                    phone: widget.phone,
                                    password: widget.password,
                                    extraPath: widget.extraPath,
                                  ),
                              child: const Text('Попробовать снова'),
                            ),
                  ),
                ],
              ),
            );
          } else if (controller.webViewController != null) {
            return GestureDetector(
              onTap: () {
                if (!pageInteracted) {
                  pageInteracted = true;
                  controller.forceHideLoading();
                }
              },
              child: Stack(
                children: [
                  WebViewWidget(controller: controller.webViewController!),
                  if (controller.isLoading.value)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          } else {
            return const Center(
              child: Text('Что-то пошло не так. Пожалуйста, попробуйте снова.'),
            );
          }
        }),
      ),
    );
  }
}
