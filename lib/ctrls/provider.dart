import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:http/io_client.dart';

class KaspiResponse {
  final int statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? data;

  KaspiResponse({required this.statusCode, this.statusMessage, this.data});
}

class KaspiApiClient {
  final String _baseUrl;
  final Duration _timeout = Duration(seconds: 30);

  KaspiApiClient(String ipAddress) : _baseUrl = 'https://$ipAddress:8080/v2';

  // Custom HTTP client with SSL certificate bypass
  http.Client _createClient() {
    HttpClient client =
        HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;

    return IOClient(client);
  }

  void _logRequest(
    String method,
    String url,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  ) {
    if (queryParams != null) {}
    if (headers != null) {}
  }

  void _logResponse(http.Response response) {}

  void _logError(String method, String url, dynamic error) {}

  KaspiResponse _processResponse(http.Response response) {
    try {
      final responseBody =
          response.body.isNotEmpty ? json.decode(response.body) : null;

      if (response.statusCode == 200) {
        return KaspiResponse(
          statusCode: response.statusCode,
          statusMessage: response.reasonPhrase,
          data: responseBody,
        );
      } else {
        return KaspiResponse(
          statusCode: response.statusCode,
          statusMessage: response.reasonPhrase,
          data: {'errorText': response.body},
        );
      }
    } catch (e) {
      return KaspiResponse(
        statusCode: response.statusCode,
        statusMessage: 'Error parsing response: $e',
        data: {'errorText': 'Failed to parse response: ${response.body}'},
      );
    }
  }

  Future<KaspiResponse> register(String name) async {
    final client = _createClient();
    final url = Uri.parse(
      '$_baseUrl/register',
    ).replace(queryParameters: {'name': name});

    try {
      _logRequest('GET', url.toString(), {'name': name}, null);

      final response = await client.get(url).timeout(_timeout);
      _logResponse(response);

      return _processResponse(response);
    } catch (e) {
      _logError('GET', url.toString(), e);
      return KaspiResponse(
        statusCode: 0,
        statusMessage: 'Connection error',
        data: {'errorText': e.toString()},
      );
    } finally {
      client.close();
    }
  }

  Future<KaspiResponse> revokeToken(
    String refreshToken,
    String name,
    String token,
  ) async {
    final client = _createClient();
    final url = Uri.parse(
      '$_baseUrl/revoke',
    ).replace(queryParameters: {'refreshToken': refreshToken, 'name': name});

    try {
      final headers = {'accesstoken': token};
      _logRequest('GET', url.toString(), {
        'refreshToken': refreshToken,
        'name': name,
      }, headers);

      final response = await client
          .get(url, headers: headers)
          .timeout(_timeout);
      _logResponse(response);

      return _processResponse(response);
    } catch (e) {
      _logError('GET', url.toString(), e);
      return KaspiResponse(
        statusCode: 0,
        statusMessage: 'Connection error',
        data: {'errorText': e.toString()},
      );
    } finally {
      client.close();
    }
  }

  Future<KaspiResponse> payment(
    String amount,
    String token, {
    bool ownCheque = true,
  }) async {
    final client = _createClient();
    final url = Uri.parse('$_baseUrl/payment').replace(
      queryParameters: {'amount': amount, 'owncheque': ownCheque.toString()},
    );

    try {
      final headers = {'accesstoken': token};
      _logRequest('GET', url.toString(), {
        'amount': amount,
        'owncheque': ownCheque.toString(),
      }, headers);

      final response = await client
          .get(url, headers: headers)
          .timeout(_timeout);
      _logResponse(response);

      return _processResponse(response);
    } catch (e) {
      _logError('GET', url.toString(), e);
      return KaspiResponse(
        statusCode: 0,
        statusMessage: 'Connection error',
        data: {'errorText': e.toString()},
      );
    } finally {
      client.close();
    }
  }

  Future<KaspiResponse> status(String processId, String token) async {
    final client = _createClient();
    final url = Uri.parse(
      '$_baseUrl/status',
    ).replace(queryParameters: {'processId': processId});

    try {
      final headers = {'accesstoken': token};
      _logRequest('GET', url.toString(), {'processId': processId}, headers);

      final response = await client
          .get(url, headers: headers)
          .timeout(_timeout);
      _logResponse(response);

      return _processResponse(response);
    } catch (e) {
      _logError('GET', url.toString(), e);
      return KaspiResponse(
        statusCode: 0,
        statusMessage: 'Connection error',
        data: {'errorText': e.toString()},
      );
    } finally {
      client.close();
    }
  }

  Future<KaspiResponse> refund(
    String method,
    String amount,
    String transactionId,
    String token, {
    bool ownCheque = true,
  }) async {
    final client = _createClient();
    final url = Uri.parse('$_baseUrl/refund').replace(
      queryParameters: {
        'method': method,
        'amount': amount,
        'transactionId': transactionId,
        'owncheque': ownCheque.toString(),
      },
    );

    try {
      final headers = {'accesstoken': token};
      _logRequest('GET', url.toString(), {
        'method': method,
        'amount': amount,
        'transactionId': transactionId,
        'owncheque': ownCheque.toString(),
      }, headers);

      final response = await client
          .get(url, headers: headers)
          .timeout(_timeout);
      _logResponse(response);

      return _processResponse(response);
    } catch (e) {
      _logError('GET', url.toString(), e);
      return KaspiResponse(
        statusCode: 0,
        statusMessage: 'Connection error',
        data: {'errorText': e.toString()},
      );
    } finally {
      client.close();
    }
  }

  Future<KaspiResponse> actualize(String processId, String token) async {
    final client = _createClient();
    final url = Uri.parse(
      '$_baseUrl/actualize',
    ).replace(queryParameters: {'processId': processId});

    try {
      final headers = {'accesstoken': token};
      _logRequest('GET', url.toString(), {'processId': processId}, headers);

      final response = await client
          .get(url, headers: headers)
          .timeout(_timeout);
      _logResponse(response);

      return _processResponse(response);
    } catch (e) {
      _logError('GET', url.toString(), e);
      return KaspiResponse(
        statusCode: 0,
        statusMessage: 'Connection error',
        data: {'errorText': e.toString()},
      );
    } finally {
      client.close();
    }
  }

  Future<KaspiResponse> deviceInfo(String token) async {
    final client = _createClient();
    final url = Uri.parse('$_baseUrl/deviceinfo');

    try {
      final headers = {'accesstoken': token};
      _logRequest('GET', url.toString(), null, headers);

      final response = await client
          .get(url, headers: headers)
          .timeout(_timeout);
      _logResponse(response);

      return _processResponse(response);
    } catch (e) {
      _logError('GET', url.toString(), e);
      return KaspiResponse(
        statusCode: 0,
        statusMessage: 'Connection error',
        data: {'errorText': e.toString()},
      );
    } finally {
      client.close();
    }
  }

  Future<bool> testInternetConnection({Duration? timeout}) async {
    final connectTimeout = timeout ?? Duration(seconds: 5);
    try {
      final result = await InternetAddress.lookup(
        '8.8.8.8',
      ).timeout(connectTimeout);

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }

      return false;
    } on SocketException catch (e) {
      Get.snackbar("Внимание", "Ошибка $e");
      return false;
    } on TimeoutException catch (e) {
      Get.snackbar("Внимание", "Ошибка $e");
      return false;
    } catch (e) {
      Get.snackbar("Внимание", "Ошибка $e");
      return false;
    }
  }

  Future<bool> testTerminalConnection({Duration? timeout}) async {
    final connectTimeout = timeout ?? Duration(seconds: 5);
    try {
      final parts = _baseUrl.replaceAll('https://', '').split(':');
      if (parts.isEmpty) {
        return false;
      }

      final host = parts[0];

      final socket = await Socket.connect(host, 8080).timeout(connectTimeout);
      socket.destroy();

      return true;
    } on SocketException catch (e) {
      Get.snackbar("Внимание", "Ошибка $e");
      return false;
    } on TimeoutException catch (e) {
      Get.snackbar("Внимание", "Ошибка $e");
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<KaspiResponse> resetTransactions() async {
    final client = _createClient();
    final url = Uri.parse('$_baseUrl/reset');

    try {
      _logRequest('GET', url.toString(), null, null);

      final response = await client.get(url).timeout(_timeout);
      _logResponse(response);

      return _processResponse(response);
    } catch (e) {
      _logError('GET', url.toString(), e);
      return KaspiResponse(
        statusCode: 0,
        statusMessage: 'Connection error',
        data: {'errorText': e.toString()},
      );
    } finally {
      client.close();
    }
  }
}
