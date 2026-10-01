/**
 * Unit Tests: Modular HTTP Routing & Middleware
 * Author: Eng. MHD. Shadi AL-Hasan <mhd.shadi.alhasan@gmail.com>
 * Phone: +963934005922
 * Copyright (c) 2026 MHD. Shadi AL-Hasan
 */

import 'package:flutter_modular_template/core/errors/app_error_codes.dart';
import 'package:flutter_modular_template/core/network/http_router.dart';
import 'package:flutter_modular_template/core/network/network_models.dart';
import 'package:test/test.dart';

void main() {
  group('ModularHttpRouter Unit Tests', () {
    late ModularHttpRouter router;

    setUp(() {
      router = ModularHttpRouter();

      router.get('/health', (req) async {
        return HttpResponseData(
          statusCode: 200,
          data: {
            'status': 'UP',
            'version': '1.0.0',
            'maintainer': 'Eng. MHD. Shadi AL-Hasan',
          },
        );
      });

      router.get('/api/v1/users/:id', (req) async {
        return HttpResponseData(
          statusCode: 200,
          data: {
            'id': 101,
            'name': 'Eng. MHD. Shadi AL-Hasan',
            'role': 'Solutions Architect',
          },
        );
      });

      router.post('/api/v1/auth/login', (req) async {
        final body = req.body as Map<String, dynamic>?;
        if (body?['email'] == 'mhd.shadi.alhasan@gmail.com') {
          return HttpResponseData(
            statusCode: 200,
            data: {'token': 'valid_token_123'},
          );
        }
        return HttpResponseData(
          statusCode: 401,
          errorMessage: 'Invalid credentials',
        );
      });
    });

    test('dispatches GET /health successfully', () async {
      final res = await router.dispatch(
        HttpRequestOptions(path: '/health', method: HttpMethod.GET),
      );

      expect(res.statusCode, equals(200));
      expect(res.isSuccess, isTrue);
      expect((res.data as Map)['status'], equals('UP'));
      expect(
          (res.data as Map)['maintainer'], equals('Eng. MHD. Shadi AL-Hasan'));
    });

    test('dispatches parameterized route /api/v1/users/42', () async {
      final res = await router.dispatch(
        HttpRequestOptions(path: '/api/v1/users/42', method: HttpMethod.GET),
      );

      expect(res.statusCode, equals(200));
      expect((res.data as Map)['id'], equals(101));
    });

    test('dispatches POST /api/v1/auth/login with valid body', () async {
      final res = await router.dispatch(
        HttpRequestOptions(
          path: '/api/v1/auth/login',
          method: HttpMethod.POST,
          body: {'email': 'mhd.shadi.alhasan@gmail.com'},
        ),
      );

      expect(res.statusCode, equals(200));
      expect((res.data as Map)['token'], equals('valid_token_123'));
    });

    test('throws ROUTE_NOT_FOUND exception when accessing unregistered route',
        () async {
      expect(
        () => router.dispatch(
          HttpRequestOptions(path: '/api/v1/unknown', method: HttpMethod.GET),
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            equals(AppErrorCode.ROUTE_NOT_FOUND),
          ),
        ),
      );
    });

    test('throws METHOD_NOT_ALLOWED exception when HTTP method mismatches',
        () async {
      expect(
        () => router.dispatch(
          HttpRequestOptions(path: '/health', method: HttpMethod.POST),
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            equals(AppErrorCode.METHOD_NOT_ALLOWED),
          ),
        ),
      );
    });

    test('executes middleware pipeline before dispatching', () async {
      var middlewareCalled = false;
      router.use((req) async {
        middlewareCalled = true;
        req.headers['X-Request-Trace'] = 'trace_999';
      });

      final req = HttpRequestOptions(path: '/health', method: HttpMethod.GET);
      final res = await router.dispatch(req);

      expect(middlewareCalled, isTrue);
      expect(req.headers['X-Request-Trace'], equals('trace_999'));
      expect(res.statusCode, equals(200));
    });
  });
}
