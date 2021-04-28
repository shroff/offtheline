part of 'actions.dart';

const _boxNameActionQueue = 'apiActionQueue';

const _keyActionName = 'name';
const _keyActionProps = 'props';
const _keyActionData = 'data';

class ActionQueueCubit<T extends ApiCubit> extends Cubit<ActionQueueState<T>> {
  final T api;
  final Map<String, ApiActionDeserializer<T>> deserializers;
  late final Box<Map> _actions;

  ActionQueueCubit(this.api, this.deserializers)
      : super(ActionQueueState<T>()) {
    _initialize();
  }

  void _initialize() async {
    _actions = await Hive.openBox(_boxNameActionQueue);

    final session = api.state.session;
    if (session == null) {
      _actions.clear();
    }

    _actions.watch().listen((event) {
      emit(state.copyWithActions(
        _actions.values.map((data) => _deserializeAction(data)),
      ));
      _sendNextRequest();
    });

    api.stream.listen((apiState) {
      if (apiState.session == null) {
        if (_actions.isOpen) {
          _actions.clear();
        }
        emit(ActionQueueState<T>(
          ready: true,
          actions: [],
        ));
      }
    });

    emit(ActionQueueState<T>(
      ready: true,
      actions: _actions.values.map((data) => _deserializeAction(data)),
    ));
    _sendNextRequest();
  }

  @override
  Future<void> close() async {
    debugPrint('[action-queue] Closing');
    await _actions.close();
    await super.close();
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
    final session = api.state.session;
    if (session == null) {
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
    final session = api.state.session;
    if (session == null) {
      return;
    }

    if (index >= _actions.length || (index == 0 && state.submitting)) {
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
    if (api.state.session == null) {
      return;
    }
    final session = api.state.session;

    if (_actions.isEmpty ||
        (state.error?.isNotEmpty ?? false) ||
        state.paused ||
        state.submitting) {
      return;
    }

    emit(state.copyWithSubmitting(true, null));

    final action = _deserializeAction(_actions.getAt(0)!);
    final request = action.createRequest(api);

    final error = await api.sendRequest(request);

    if (session!.sessionId != api.state.session?.sessionId) return;

    emit(state.copyWithSubmitting(false, error));
    if (error == null) {
      removeAt(0, revert: false);
    }
  }
}
