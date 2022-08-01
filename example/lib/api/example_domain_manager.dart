import 'package:offtheline/offtheline.dart';

import 'example_domain.dart';
import 'user_agent.dart';

const actionDeserializers = <String, ApiActionDeserializer>{};

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
