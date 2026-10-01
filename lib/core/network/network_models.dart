/**
 * Network HTTP Models and Router Types
 * Author: Eng. MHD. Shadi AL-Hasan <mhd.shadi.alhasan@gmail.com>
 * Phone: +963934005922
 * Copyright (c) 2026 MHD. Shadi AL-Hasan
 */

enum HttpMethod { GET, POST, PUT, DELETE, PATCH, HEAD }

class HttpRequestOptions {
  final String path;
  final HttpMethod method;
  final Map<String, String> headers;
  final Map<String, dynamic>? queryParameters;
  final dynamic body;

  HttpRequestOptions({
    required this.path,
    required this.method,
    Map<String, String>? headers,
    this.queryParameters,
    this.body,
  }) : headers = headers ?? {};

  Map<String, dynamic> toJson() => {
        'path': path,
        'method': method.name,
        'headers': headers,
        'queryParameters': queryParameters,
        'body': body,
      };
}

class HttpResponseData<T> {
  final int statusCode;
  final T? data;
  final Map<String, String> headers;
  final String? errorMessage;
  final bool isSuccess;

  HttpResponseData({
    required this.statusCode,
    this.data,
    Map<String, String>? headers,
    this.errorMessage,
  })  : headers = headers ?? {},
        isSuccess = statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'isSuccess': isSuccess,
        'data': data,
        'headers': headers,
        'errorMessage': errorMessage,
      };
}
