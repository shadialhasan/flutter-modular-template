/**
 * Robust State Machine Engine for Modular Feature Architectures
 * Author: Eng. MHD. Shadi AL-Hasan <mhd.shadi.alhasan@gmail.com>
 * Phone: +963934005922
 * Copyright (c) 2026 MHD. Shadi AL-Hasan
 */

import '../errors/app_error_codes.dart';

abstract class BaseState {
  final String name;
  const BaseState(this.name);

  @override
  String toString() => name;
}

abstract class BaseEvent {
  final String name;
  const BaseEvent(this.name);

  @override
  String toString() => name;
}

class StateTransition<S extends BaseState, E extends BaseEvent> {
  final S from;
  final E event;
  final S to;

  const StateTransition({
    required this.from,
    required this.event,
    required this.to,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateTransition<S, E> &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          event == other.event &&
          to == other.to;

  @override
  int get hashCode => Object.hash(from, event, to);
}

class ModuleStateMachine<S extends BaseState, E extends BaseEvent> {
  S _currentState;
  final Set<StateTransition<S, E>> _allowedTransitions = {};
  final List<S> _history = [];
  final void Function(S from, E event, S to)? onTransition;

  ModuleStateMachine({
    required S initialState,
    Set<StateTransition<S, E>>? transitions,
    this.onTransition,
  }) : _currentState = initialState {
    _history.add(initialState);
    if (transitions != null) {
      _allowedTransitions.addAll(transitions);
    }
  }

  S get currentState => _currentState;
  List<S> get history => List.unmodifiable(_history);

  void addTransition(S from, E event, S to) {
    _allowedTransitions.add(StateTransition(from: from, event: event, to: to));
  }

  S transition(E event) {
    final candidate =
        _allowedTransitions.cast<StateTransition<S, E>?>().firstWhere(
              (t) => t?.from == _currentState && t?.event == event,
              orElse: () => null,
            );

    if (candidate == null) {
      throw AppException(
        code: AppErrorCode.INVALID_STATE_TRANSITION,
        message:
            'Illegal state transition from "$_currentState" via event "$event"',
        details: {
          'currentState': _currentState.name,
          'attemptedEvent': event.name,
          'historyCount': _history.length,
        },
      );
    }

    final previous = _currentState;
    _currentState = candidate.to;
    _history.add(_currentState);

    onTransition?.call(previous, event, _currentState);
    return _currentState;
  }

  bool can(E event) {
    return _allowedTransitions
        .any((t) => t.from == _currentState && t.event == event);
  }
}
