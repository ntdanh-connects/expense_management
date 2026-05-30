import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

class LogConsoleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['request_time'] = DateTime.now().millisecondsSinceEpoch;

    final requestBody = _parseBody(options.data);
    final headers = options.headers;
    final queryParams = options.queryParameters;

    final details = {
      'type': 'request',
      'url': options.uri.toString(),
      'method': options.method,
      'headers': headers,
      'queryParams': queryParams,
      'body': requestBody,
    };

    AppLogger.network(
      "🚀 [REQUEST] ${options.method} ${options.path}",
      tag: "NetworkReq",
      details: details,
    );

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['request_time'] as int?;
    final latency = startTime != null
        ? "${DateTime.now().millisecondsSinceEpoch - startTime}ms"
        : "unknown";

    final responseBody = _parseBody(response.data);
    final headers = response.headers.map;

    final details = {
      'type': 'response',
      'url': response.requestOptions.uri.toString(),
      'method': response.requestOptions.method,
      'statusCode': response.statusCode,
      'latency': latency,
      'headers': headers,
      'body': responseBody,
    };

    AppLogger.network(
      "✅ [RESPONSE] ${response.statusCode} | ${response.requestOptions.method} ${response.requestOptions.path} ($latency)",
      tag: "NetworkRes",
      details: details,
    );

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['request_time'] as int?;
    final latency = startTime != null
        ? "${DateTime.now().millisecondsSinceEpoch - startTime}ms"
        : "unknown";

    final responseBody = _parseBody(err.response?.data);
    final headers = err.response?.headers.map;

    final details = {
      'type': 'error',
      'url': err.requestOptions.uri.toString(),
      'method': err.requestOptions.method,
      'statusCode': err.response?.statusCode,
      'latency': latency,
      'headers': headers,
      'error': err.message,
      'errorType': err.type.toString(),
      'body': responseBody,
    };

    AppLogger.error(
      "❌ [HTTP ERROR] ${err.response?.statusCode ?? 'No Code'} | ${err.requestOptions.method} ${err.requestOptions.path} ($latency)\nError: ${err.message}",
      tag: "NetworkErr",
      details: details,
    );

    return handler.next(err);
  }

  dynamic _parseBody(dynamic data) {
    if (data == null) return null;
    if (data is Map || data is List) {
      return data;
    }
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data.toString();
  }
}
