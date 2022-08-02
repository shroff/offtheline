import 'package:example/api/actions/add_note_action.dart';
import 'package:example/api/actions/edit_starred_action.dart';
import 'package:offtheline/offtheline.dart';

import 'example_domain.dart';
import 'user_agent.dart';

const actionDeserializers = {
  AddNoteAction.actionName: AddNoteAction.deserialize,
  EditStarredAction.actionName: EditStarredAction.deserialize,
};

class ExampleDomainManager extends DomainManager<ExampleDomain> {
  ExampleDomainManager._();

  static Future<ExampleDomainManager> create() async {
    await initilizeUserAgent();
    final domainManager = ExampleDomainManager._();
    await domainManager.initialize();
    return domainManager;
  }

  @override
  Future<ExampleDomain?> restoreDomain(String id) {
    return ExampleDomain.open(id, clear: false);
  }
}
