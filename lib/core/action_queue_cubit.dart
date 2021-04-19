import 'package:appcore/core/api.dart';
import 'package:appcore/requests/api_action.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'action_queue_state.dart';

const _boxNameActionQueue = 'apiActionQueue';

const _keyActionName = 'name';
const _keyActionProps = 'props';
const _keyActionData = 'data';

abstract class ActionQueueCubit<
    D extends Datastore<D, S, T>,
    S extends ApiSession,
    T extends ApiCubit<D, S, T>> extends Cubit<ActionQueueState> {
  final ApiCubit<D, S, T> api;

  late final Box<Map> _actions;

  Map<String, ApiActionDeserializer<D, S, T>> get deserializers;

  ActionQueueCubit(this.api) : super(ActionQueueState<D, S, T>()) {
    _initialize();
  }

  void _initialize() async {
    _actions = await Hive.openBox(_boxNameActionQueue);

    while (!api.state.ready) {
      await api.stream.firstWhere((state) => state.ready);
    }

    if (api.isSignedIn) {
      emit(ActionQueueState<D, S, T>(
        ready: true,
        actions: _actions.values.map((data) => _deserializeAction(data)),
      ));
      _sendNextRequest();
    } else {
      _actions.clear();
    }

    api.stream.listen((state) {
      if (state.ready && !state.isSignedIn) {
        _actions.clear();
      }
    });

    _actions.watch().listen((event) {
      emit(state.copyWithActions(
        _actions.values.map((data) => _deserializeAction(data)),
      ));
      _sendNextRequest();
    });
  }

  ApiAction<D, S, T> _deserializeAction(Map<dynamic, dynamic> actionMap) {
    final name = actionMap[_keyActionName];
    assert(deserializers.containsKey(name));
    final props = actionMap[_keyActionProps] as Map;
    final data = actionMap[_keyActionData];
    final action = deserializers[name]!(props.cast<String, dynamic>(), data);
    return action;
  }

  Future<void> enqueueOfflineAction(ApiAction<D, S, T> action) async {
    await awaitReady();

    if (!api.isSignedIn) {
      return;
    }

    await action.applyOptimisticUpdate(api);
    debugPrint('[api] Request enqueued: ${action.generateDescription(api)}');
    await _actions.add({
      _keyActionName: action.name,
      _keyActionProps: action.toMap(),
      _keyActionData: action.binaryData,
    });
  }

  Future<void> deleteRequestAt(int index, {bool revert = true}) async {
    await awaitReady();

    if (!api.isSignedIn ||
        index >= _actions.length ||
        (index == 0 && state.submitting)) {
      return;
    }

    final action = _deserializeAction(_actions.getAt(index)!);
    if (revert) {
      await action.revertOptimisticUpdate(api);
    }

    if (kDebugMode) {
      debugPrint('[api] Deleting request: ${action.generateDescription(api)}');
    }
    if (index == 0 && state.error != null) {
      // Cannot be submitting request at index 0
      emit(state.copyWithSubmitting(false, null));
    }
    await _actions.deleteAt(index);
  }

  void pause() {
    debugPrint('[api] Pausing');
    emit(state.copyWithPaused(true));
  }

  void resume() {
    debugPrint('[api] Resuming');
    emit(state.copyWithPaused(false));
    _sendNextRequest();
  }

  void _sendNextRequest() async {
    await awaitReady();

    if (!api.isSignedIn ||
        _actions.isEmpty ||
        (state.error?.isNotEmpty ?? false) ||
        state.paused ||
        state.submitting) {
      return;
    }

    emit(state.copyWithSubmitting(true, null));

    final action = _deserializeAction(_actions.getAt(0)!);
    final request = action.createRequest(api);

    final error = await api.sendRequest(request);
    emit(state.copyWithSubmitting(false, error));
    if (error == null) {
      deleteRequestAt(0, revert: false);
    }
  }

  Future<void> awaitReady() async {
    while (!api.state.ready || !state.ready) {
      while (!api.state.ready) {
        await api.stream.firstWhere((state) => state.ready);
      }
      while (!state.ready) {
        await stream.firstWhere((state) => state.ready);
      }
    }
  }
}
