part of 'action_queue.dart';

const _boxNameActionQueue = 'apiActionQueue';

const _keyActionName = 'name';
const _keyActionProps = 'props';
const _keyActionData = 'data';

typedef ApiActionDeserializer<T extends DomainApi> = ApiAction<T> Function(
    Map<String, dynamic> props, dynamic data);

class ActionQueueCubit<T extends DomainApi> extends Cubit<ActionQueueState<T>> {
  final T api;
  final Map<String, ApiActionDeserializer<T>> deserializers;
  late final Box<Map> _actions;
  late final void Function(dynamic) _successfulResponseProcessor = (response) {
    _sendNextRequest();
  };

  ActionQueueCubit(this.api, this.deserializers)
      : super(ActionQueueState<T>()) {
    _initialize();
  }

  void _initialize() async {
    _actions = await Hive.openBox(_boxNameActionQueue);

    // Automatically dispatch actions when added to queue
    _actions.watch().listen((event) {
      emit(state.copyWithActions(
        _actions.values.map((data) => _deserializeAction(data)),
      ));
      _sendNextRequest();
    });

    // Try sending the next action when a successful resopnse is parsed
    api.addResponseProcessor(_successfulResponseProcessor);

    emit(ActionQueueState<T>(
      ready: true,
      actions: _actions.values.map((data) => _deserializeAction(data)),
    ));
    _sendNextRequest();
  }

  Future<void> clear() async {
    if (_actions.isOpen) {
      await _actions.clear();
    }
    emit(ActionQueueState<T>(
      ready: true,
      actions: [],
    ));
  }

  @override
  Future<void> close() async {
    debugPrint('[actions] Closing');
    api.removeResponseProcessor(_successfulResponseProcessor);
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
    await action.applyOptimisticUpdate(api);
    debugPrint(
        '[actions] Request enqueued: ${action.generateDescription(api)}');
    await _actions.add({
      _keyActionName: action.name,
      _keyActionProps: action.toMap(),
      _keyActionData: action.binaryData,
    });
  }

  Future<void> removeAt(int index, {bool revert = true}) async {
    if (index >= _actions.length || (index == 0 && state.submitting)) {
      return;
    }

    final action = _deserializeAction(_actions.getAt(index)!);
    if (revert) {
      await action.revertOptimisticUpdate(api);
    }

    if (kDebugMode) {
      debugPrint(
          '[aapipi] Deleting request: ${action.generateDescription(api)}');
    }
    if (index == 0 && state.error != null) {
      // Cannot be submitting request at index 0
      emit(state.copyWithSubmitting(false, null));
    }
    await _actions.deleteAt(index);
  }

  void pause() {
    debugPrint('[aapipi] Pausing');
    emit(state.copyWithPaused(true));
  }

  void resume() {
    debugPrint('[aapipi] Resuming');
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

    emit(state.copyWithSubmitting(false, error));
    if (error == null) {
      removeAt(0, revert: false);
    }
  }
}
