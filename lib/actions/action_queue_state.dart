part of 'actions.dart';

class ActionQueueState<T extends ApiCubit> {
  final bool ready;
  final Iterable<ApiAction<T>> actions;
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

  ActionQueueState<T> copyWithPaused(bool paused) {
    return ActionQueueState(
      ready: ready,
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: null,
    );
  }

  ActionQueueState<T> copyWithSubmitting(bool submitting, String? error) {
    return ActionQueueState(
      ready: ready,
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: error,
    );
  }

  ActionQueueState<T> copyWithActions(Iterable<ApiAction<T>> actions) {
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

    return o is ActionQueueState<T> &&
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
    return 'ActionQueueState(ready: $ready, actions: $actions, paused: $paused, submitting: $submitting, error: $error)';
  }
}
