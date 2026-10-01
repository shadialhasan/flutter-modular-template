/**
 * Modular HTTP Router with Pattern Matching & Middleware
 * Author: Eng. MHD. Shadi AL-Hasan <mhd.shadi.alhasan@gmail.com>
 * Phone: +963934005922
 * Copyright (c) 2026 MHD. Shadi AL-Hasan
 */

import '../errors/app_error_codes.dart';
import 'network_models.dart';

typedef RouteHandler = Future<HttpResponseData> Function(
    HttpRequestOptions request);
typedef MiddlewareHandler = Future<void> Function(HttpRequestOptions request);

class RouteEntry {
  final String path;
  final HttpMethod method;
  final RouteHandler handler;

  const RouteEntry({
    required this.path,
    required this.method,
    required this.handler,
  });
}

class ModularHttpRouter {
  final List<RouteEntry> _routes = [];
  final List<MiddlewareHandler> _middlewares = [];

  void use(MiddlewareHandler middleware) {
    _middlewares.add(middleware);
  }

  void register(HttpMethod method, String path, RouteHandler handler) {
    _routes.add(RouteEntry(path: path, method: method, handler: handler));
  }

  void get(String path, RouteHandler handler) =>
      register(HttpMethod.GET, path, handler);
  void post(String path, RouteHandler handler) =>
      register(HttpMethod.POST, path, handler);
  void put(String path, RouteHandler handler) =>
      register(HttpMethod.PUT, path, handler);
  void delete(String path, RouteHandler handler) =>
      register(HttpMethod.DELETE, path, handler);

  List<RouteEntry> get registeredRoutes => List.unmodifiable(_routes);

  Future<HttpResponseData> dispatch(HttpRequestOptions request) async {
    // Run middlewares
    for (final middleware in _middlewares) {
      await middleware(request);
    }

    // Match route
    final matchingPathRoutes =
        _routes.where((r) => _matchPath(r.path, request.path)).toList();

    if (matchingPathRoutes.isEmpty) {
      throw AppException(
        code: AppErrorCode.ROUTE_NOT_FOUND,
        message: 'No handler registered for path: ${request.path}',
        details: {'path': request.path, 'method': request.method.name},
      );
    }

    final matchedRoute = matchingPathRoutes.cast<RouteEntry?>().firstWhere(
          (r) => r?.method == request.method,
          orElse: () => null,
        );

    if (matchedRoute == null) {
      throw AppException(
        code: AppErrorCode.METHOD_NOT_ALLOWED,
        message:
            'Method ${request.method.name} not allowed for path: ${request.path}',
        details: {
          'path': request.path,
          'allowedMethods':
              matchingPathRoutes.map((r) => r.method.name).toList()
        },
      );
    }

    return await matchedRoute.handler(request);
  }

  bool _matchPath(String pattern, String actual) {
    if (pattern == actual) return true;
    final patternSegments =
        pattern.split('/').where((s) => s.isNotEmpty).toList();
    final actualSegments =
        actual.split('/').where((s) => s.isNotEmpty).toList();

    if (patternSegments.length != actualSegments.length) return false;

    for (int i = 0; i < patternSegments.length; i++) {
      if (patternSegments[i].startsWith(':')) {
        continue; // Dynamic path variable match
      }
      if (patternSegments[i] != actualSegments[i]) {
        return false;
      }
    }
    return true;
  }
}
