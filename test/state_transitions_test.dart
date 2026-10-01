/**
 * Unit Tests: State Transitions and State Machine
 * Author: Eng. MHD. Shadi AL-Hasan <mhd.shadi.alhasan@gmail.com>
 * Phone: +963934005922
 * Copyright (c) 2026 MHD. Shadi AL-Hasan
 */

import 'package:flutter_modular_template/core/errors/app_error_codes.dart';
import 'package:flutter_modular_template/core/state/state_machine.dart';
import 'package:flutter_modular_template/features/auth/domain/models/auth_user.dart';
import 'package:flutter_modular_template/features/auth/presentation/auth_state_controller.dart';
import 'package:test/test.dart';

class MockState extends BaseState {
  const MockState(super.name);
}

class MockEvent extends BaseEvent {
  const MockEvent(super.name);
}

void main() {
  group('ModuleStateMachine Generic Tests', () {
    const sIdle = MockState('Idle');
    const sRunning = MockState('Running');
    const sFinished = MockState('Finished');

    const eStart = MockEvent('Start');
    const eComplete = MockEvent('Complete');
    const eReset = MockEvent('Reset');

    late ModuleStateMachine<MockState, MockEvent> sm;

    setUp(() {
      sm = ModuleStateMachine<MockState, MockEvent>(
        initialState: sIdle,
        transitions: {
          const StateTransition(from: sIdle, event: eStart, to: sRunning),
          const StateTransition(
              from: sRunning, event: eComplete, to: sFinished),
          const StateTransition(from: sFinished, event: eReset, to: sIdle),
        },
      );
    });

    test('valid state sequence Idle -> Running -> Finished -> Idle', () {
      expect(sm.currentState, equals(sIdle));
      expect(sm.can(eStart), isTrue);
      expect(sm.can(eComplete), isFalse);

      sm.transition(eStart);
      expect(sm.currentState, equals(sRunning));

      sm.transition(eComplete);
      expect(sm.currentState, equals(sFinished));

      sm.transition(eReset);
      expect(sm.currentState, equals(sIdle));
      expect(sm.history.length, equals(4));
    });

    test('throws AppException on invalid transition', () {
      expect(
        () => sm.transition(eComplete),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            equals(AppErrorCode.INVALID_STATE_TRANSITION),
          ),
        ),
      );
    });
  });

  group('AuthStateController State Transitions', () {
    late AuthStateController controller;
    final testUser = AuthUser(
      id: 'usr_001',
      email: 'mhd.shadi.alhasan@gmail.com',
      name: 'Eng. MHD. Shadi AL-Hasan',
      role: 'CTO',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final testToken = AuthToken(
      accessToken: 'jwt_mock_token_abc',
      refreshToken: 'jwt_refresh_xyz',
      expiresAt: DateTime.utc(2026, 12, 31),
    );

    setUp(() {
      controller = AuthStateController();
    });

    test('initial state is AuthUnauthenticated', () {
      expect(controller.state, isA<AuthUnauthenticated>());
      expect(controller.history.length, equals(1));
    });

    test(
        'successful login transition flow: Unauthenticated -> Authenticating -> Authenticated',
        () {
      controller.handleEvent(const SubmitLoginEvent());
      expect(controller.state, isA<AuthAuthenticating>());

      controller
          .handleEvent(LoginSuccessEvent(user: testUser, token: testToken));
      expect(controller.state, isA<AuthAuthenticated>());

      final authenticatedState = controller.state as AuthAuthenticated;
      expect(
          authenticatedState.user.email, equals('mhd.shadi.alhasan@gmail.com'));
      expect(authenticatedState.user.role, equals('CTO'));
      expect(
          authenticatedState.token.accessToken, equals('jwt_mock_token_abc'));
    });

    test(
        'failed login transition flow: Unauthenticated -> Authenticating -> AuthError',
        () {
      controller.handleEvent(const SubmitLoginEvent());
      controller.handleEvent(const LoginFailureEvent(
        code: AppErrorCode.AUTH_UNAUTHORIZED,
        message: 'Invalid email or password',
      ));

      expect(controller.state, isA<AuthError>());
      final err = controller.state as AuthError;
      expect(err.code, equals(AppErrorCode.AUTH_UNAUTHORIZED));
      expect(err.message, contains('Invalid email'));
    });

    test('token expiry and logout flow', () {
      controller.handleEvent(const SubmitLoginEvent());
      controller
          .handleEvent(LoginSuccessEvent(user: testUser, token: testToken));
      expect(controller.state, isA<AuthAuthenticated>());

      controller.handleEvent(const ExpireTokenEvent());
      expect(controller.state, isA<AuthTokenExpired>());

      controller.handleEvent(const LogoutEvent());
      expect(controller.state, isA<AuthUnauthenticated>());
    });

    test(
        'disallows invalid transition directly from Unauthenticated with LoginSuccessEvent',
        () {
      expect(
        () => controller
            .handleEvent(LoginSuccessEvent(user: testUser, token: testToken)),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            equals(AppErrorCode.INVALID_STATE_TRANSITION),
          ),
        ),
      );
    });
  });
}
