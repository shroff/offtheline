import 'package:state_notifier/state_notifier.dart';

class ViewPrefsManager extends StateNotifier<ViewPrefs> with LocatorMixin {
  bool get showArchived => state.showArchived;
  set showArchived(bool value) {
    state = ViewPrefs(showArchived: value);
  }

  ViewPrefsManager(super.state);
}

class ViewPrefs {
  final bool showArchived;

  const ViewPrefs({required this.showArchived});
}
