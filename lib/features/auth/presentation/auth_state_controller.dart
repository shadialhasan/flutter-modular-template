/**
 * Authentication State Controller and Transitions
 * Author: Eng. MHD. Shadi AL-Hasan <mhd.shadi.alhasan@gmail.com>
 * Phone: +963934005922
 * Copyright (c) 2026 MHD. Shadi AL-Hasan
 */

import '../../../core/errors/app_error_codes.dart';
import '../../../core/state/state_machine.dart';
import '../domain/models/auth_user.dart';

sealed class AuthState extends BaseState {
  const AuthState(super.name);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated() : super('Unauthenticated');
}

class AuthAuthenticating extends AuthState {
  const AuthAuthenticating() : super('Authenticating');
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;
  final AuthToken token;

  const AuthAuthenticated({required this.user, required this.token})
      : super('Authenticated');

  @override
  String toString() => 'Authenticated(user: ${user.email})';
}

class AuthTokenExpired extends AuthState {
  final AuthUser user;

  const AuthTokenExpired({required this.user}) : super('TokenExpired');
}

class AuthError extends AuthState {
  final AppErrorCode code;
  final String message;

  const AuthError({required this.code, required this.message}) : super('Error');

  @override
  String toString() => 'AuthError(${code.code}: $message)';
}

sealed class AuthEvent extends BaseEvent {
  const AuthEvent(super.name);
}

class SubmitLoginEvent extends AuthEvent {
  const SubmitLoginEvent() : super('SubmitLogin');
}

class LoginSuccessEvent extends AuthEvent {
  final AuthUser user;
  final AuthToken token;
  const LoginSuccessEvent({required this.user, required this.token})
      : super('LoginSuccess');
}

class LoginFailureEvent extends AuthEvent {
  final AppErrorCode code;
  final String message;
  const LoginFailureEvent({required this.code, required this.message})
      : super('LoginFailure');
}

class ExpireTokenEvent extends AuthEvent {
  const ExpireTokenEvent() : super('ExpireToken');
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent() : super('Logout');
}

class AuthStateController {
  AuthState _state = const AuthUnauthenticated();
  final List<AuthState> _history = [const AuthUnauthenticated()];

  AuthState get state => _state;
  List<AuthState> get history => List.unmodifiable(_history);

  void handleEvent(AuthEvent event) {
    final nextState = _resolveNextState(_state, event);
    _state = nextState;
    _history.add(_state);
  }

  AuthState _resolveNextState(AuthState current, AuthEvent event) {
    switch (current) {
      case AuthUnauthenticated():
        if (event is SubmitLoginEvent) {
          return const AuthAuthenticating();
        }
        break;

      case AuthAuthenticating():
        if (event is LoginSuccessEvent) {
          return AuthAuthenticated(user: event.user, token: event.token);
        } else if (event is LoginFailureEvent) {
          return AuthError(code: event.code, message: event.message);
        }
        break;

      case AuthAuthenticated():
        if (event is ExpireTokenEvent) {
          return AuthTokenExpired(user: current.user);
        } else if (event is LogoutEvent) {
          return const AuthUnauthenticated();
        }
        break;

      case AuthTokenExpired():
        if (event is SubmitLoginEvent) {
          return const AuthAuthenticating();
        } else if (event is LogoutEvent) {
          return const AuthUnauthenticated();
        }
        break;

      case AuthError():
        if (event is SubmitLoginEvent) {
          return const AuthAuthenticating();
        } else if (event is LogoutEvent) {
          return const AuthUnauthenticated();
        }
        break;
    }

    throw AppException(
      code: AppErrorCode.INVALID_STATE_TRANSITION,
      message: 'Invalid transition from ${current.name} on event ${event.name}',
      details: {
        'currentState': current.name,
        'event': event.name,
      },
    );
  }
}
