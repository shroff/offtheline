part of 'actions.dart';

const _boxNameActionQueue = 'apiActionQueue';

const _keyActionName = 'name';
const _keyActionProps = 'props';
const _keyActionData = 'data';

class ActionQueueCubit<S extends ApiSession, T extends ApiCubit<S>>
    extends Cubit<ActionQueueState> {
  final T api;
  final Map<String, ApiActionDeserializer<S, T>> deserializers;
  late final Box<Map> _actions;

  ActionQueueCubit(this.api, this.deserializers)
      : super(ActionQueueState<S, T>()) {
    _initialize();
  }

  void _initialize() async {
    while (!api.state.ready) {
      await api.stream.firstWhere((state) => state.ready);
    }

    _actions = await Hive.openBox(_boxNameActionQueue);

    if (api.isSignedIn) {
      emit(ActionQueueState<S, T>(
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

  ApiAction<T> _deserializeAction(Map<dynamic, dynamic> actionMap) {
    final name = actionMap[_keyActionName];
    assert(deserializers.containsKey(name));
    final props = actionMap[_keyActionProps] as Map;
    final data = actionMap[_keyActionData];
    final action = deserializers[name]!(props.cast<String, dynamic>(), data);
    return action;
  }

  Future<void> add(ApiAction<T> action) async {
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

  Future<void> removeAt(int index, {bool revert = true}) async {
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

  String generateDescription(ApiAction action) {
    return action.generateDescription(api);
  }

  String generatePayloadDetails(ApiAction action) {
    return action.generatePayloadDetails(api);
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
      removeAt(0, revert: false);
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
