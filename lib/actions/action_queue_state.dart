part of 'actions.dart';

class ActionQueueState<S extends ApiSession, T extends ApiCubit<S, T>> {
  final bool ready;
  final Iterable<ApiAction<S, T>> actions;
  final bool paused;
  final bool submitting;
  final String? error;

  const ActionQueueState({
    this.ready = false,
    this.actions = const [],
    this.paused = false,
    this.submitting = false,
    this.error,
  });

  ActionQueueState<S, T> copyWithPaused(bool paused) {
    return ActionQueueState(
      ready: ready,
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: null,
    );
  }

  ActionQueueState<S, T> copyWithSubmitting(bool submitting, String? error) {
    return ActionQueueState(
      ready: ready,
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: error,
    );
  }

  ActionQueueState<S, T> copyWithActions(Iterable<ApiAction<S, T>> actions) {
    return ActionQueueState(
      ready: true,
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: error,
    );
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ActionQueueState<S, T> &&
        o.actions == actions &&
        o.paused == paused &&
        o.submitting == submitting &&
        o.error == error;
  }

  @override
  int get hashCode {
    return actions.hashCode ^
        paused.hashCode ^
        submitting.hashCode ^
        error.hashCode;
  }

  @override
  String toString() {
    return 'ActionQueueState(actions: $actions, paused: $paused, submitting: $submitting, error: $error)';
  }
}
