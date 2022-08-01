import 'dart:async';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:offtheline/offtheline.dart';
import 'package:state_notifier/state_notifier.dart';

import 'domain.dart';
import 'logger.dart';

const _boxName = 'domains';
const _persistKeyCurrentDomain = 'currentDomain';
const _persistKeyDomainIds = 'domains';

class DomainManagerState<D extends Domain> {
  final Map<String, D> domainMap;
  final D? currentDomain;

  const DomainManagerState(this.domainMap, this.currentDomain);
}

abstract class DomainManager<D extends Domain>
    extends StateNotifier<DomainManagerState<D>> with LocatorMixin {
  late final Box _persist;

  Domain? get currentDomain => state.currentDomain;

  D? getDomain(String domainId) => state.domainMap[domainId];

  DomainManager() : super(const DomainManagerState({}, null));

  Future<void> initialize() async {
    _persist = await Hive.openBox(_boxName);
    final List<String> persistedDomainIds =
        _persist.get(_persistKeyDomainIds)?.cast<String>() ?? <String>[];
    String? currentDomainId = _persist.get(_persistKeyCurrentDomain);

    final domainMap = <String, D>{};
    bool invalidDomains = false;
    for (final domainId in persistedDomainIds) {
      logger?.d('[domain-manager] Restoring domain $domainId');
      final domain = await restoreDomain(domainId);
      if (domain == null) {
        logger?.e('[domain-manager] Domain $domainId is invalid. Deleting.');
        invalidDomains = true;
        await clearDomain(domainId);
      } else {
        domainMap[domainId] = domain;
      }
    }
    if (invalidDomains) {
      _persist.put(
          _persistKeyDomainIds, domainMap.keys.toList(growable: false));
    }

    bool invalidCurrentDomain = false;
    if (currentDomainId == null && domainMap.isNotEmpty) {
      invalidCurrentDomain = true;
      currentDomainId = domainMap.keys.first;
    } else if (currentDomainId != null &&
        !domainMap.containsKey(currentDomainId)) {
      currentDomainId = domainMap.isEmpty ? null : domainMap.keys.first;
    }
    if (invalidCurrentDomain) {
      _persist.put(_persistKeyCurrentDomain, currentDomainId);
    }

    final currentDomain = domainMap[_persist.get(_persistKeyCurrentDomain)];

    state = DomainManagerState(Map.unmodifiable(domainMap), currentDomain);
  }

  @protected
  FutureOr<D?> restoreDomain(String id);

  void addDomain(D domain) async {
    if (!state.domainMap.containsKey(domain.id)) {
      final domainMap = Map.of(state.domainMap);
      domainMap[domain.id] = domain;
      final currentDomain = state.currentDomain ?? domain;
      state = DomainManagerState(Map.unmodifiable(domainMap), currentDomain);
    }
  }

  FutureOr<void> clearDomain(String domainId) {
    final domainMap = Map.of(state.domainMap);
    final removed = domainMap.remove(domainId);
    if (removed != null) {
      final currentDomain = state.currentDomain?.id == domainId
          ? (domainMap.isEmpty ? null : domainMap.values.first)
          : state.currentDomain;
      state = DomainManagerState(Map.unmodifiable(domainMap), currentDomain);
      return removed.delete();
    }
  }
}
