import 'package:state_notifier/state_notifier.dart';

class MultiSelectManager extends StateNotifier<Set<int>> with LocatorMixin {
  MultiSelectManager() : super({});

  void clear() {
    state = {};
  }

  void toggle(int id) {
    final selected = Set.of(state);
    if (!selected.add(id)) {
      selected.remove(id);
    }
    state = selected;
  }
}
