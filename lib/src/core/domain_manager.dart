import 'dart:async';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

import 'domain.dart';
import 'logger.dart';

const _boxName = "domains";
const _persistKeyCurrentDomain = "currentDomain";
const _persistKeyDomainIds = "domains";

class DomainManagerState<D extends Domain> {
  final Map<String, D> domainMap;
  final D? currentDomain;

  const DomainManagerState(this.domainMap, this.currentDomain);
}

abstract class DomainManager<D extends Domain>
    extends StateNotifier<DomainManagerState<D>> with LocatorMixin {
  late final Box _persist;
  final Map<String, D> _domainMap = {};

  List<String> _domainIdList = List.unmodifiable([]);
  List<String> get domainIdList => _domainIdList;
  set domainIdList(List<String> domainIds) {
    _domainIdList = List.unmodifiable(domainIds);
    _persist.put(_persistKeyDomainIds, domainIds);
  }

  Domain? get currentDomain => state.currentDomain;

  String? get currentDomainId => _persist.get(_persistKeyCurrentDomain);
  set currentDomainId(String? value) {
    final domain = _domainMap[value];
    _persist.put(_persistKeyCurrentDomain, value);
    state = DomainManagerState(state.domainMap, domain);
  }

  DomainManager() : super(const DomainManagerState({}, null));

  Future<void> initialize() async {
    _persist = await Hive.openBox(_boxName);
    final List<String> domainIds =
        _persist.get(_persistKeyDomainIds)?.cast<String>() ?? <String>[];
    await Future.wait(domainIds.map((domainId) async {
      logger?.d("[domain-manager] Restoring domain $domainId");
      final domain = await restoreDomain(domainId);
      if (domain == null) {
        logger?.e("Domain is invalid. Deleting $domainId");
        await clearDomain(domainId);
      } else {
        await addDomain(domain);
      }
    }));
    if (!_domainMap.containsKey(currentDomainId)) {
      currentDomainId = domainIdList.isEmpty ? null : domainIdList[0];
    }
  }

  Future<void> addDomain(D domain) async {
    if (!domainIdList.contains(domain.id)) {
      domainIdList = List.from(domainIdList)..add(domain.id);
      _domainMap[domain.id] = domain;
      await initializeDomain(domain);
      currentDomainId ??= domainIdList.isEmpty ? null : domainIdList[0];
    }
  }

  @protected
  FutureOr<D?> restoreDomain(String id);

  @protected
  FutureOr<void> initializeDomain(D domain) {}

  FutureOr<void> clearDomain(String domainId) {
    final domain = _domainMap[domainId];
    _domainMap.remove(domainId);
    domainIdList = List.from(domainIdList)..remove(domainId);
    if (currentDomainId == domainId) {
      currentDomainId = domainIdList.isEmpty ? null : domainIdList[0];
    }
    return domain?.delete();
  }

  D? getDomain(String domainId) => _domainMap[domainId];
}
