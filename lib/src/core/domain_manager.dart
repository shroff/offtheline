import 'dart:async';

import 'package:hive/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:state_notifier/state_notifier.dart';

const _boxName = 'domains';
const _persistKeyCurrentDomainId = 'currentDomainId';
const _persistKeyDomainIds = 'domains';

class DomainManagerState<D extends Domain> {
  final Map<String, D> domainMap;
  final D? currentDomain;

  const DomainManagerState(this.domainMap, this.currentDomain);
}

/// Maintain a list of logged-in [Domain]s
class DomainManager<D extends Domain>
    extends StateNotifier<DomainManagerState<D>> with LocatorMixin {
  final FutureOr<D?> Function(String domainId) restoreDomain;
  late final Box _persist;

  DomainManager._(this.restoreDomain)
      : super(const DomainManagerState({}, null));

  /// Restore this instance and all managed [Domain]s from persistance
  static Future<DomainManager<D>> restore<D extends Domain>(
    FutureOr<D?> Function(String domainId) restoreDomain,
  ) async {
    final domainManager = DomainManager._(restoreDomain);
    await domainManager._initialize();
    return domainManager;
  }

  Future<void> _initialize() async {
    _persist = await Hive.openBox(_boxName);
    final List<String> persistedDomainIds =
        _persist.get(_persistKeyDomainIds)?.cast<String>() ?? <String>[];
    String? currentDomainId = _persist.get(_persistKeyCurrentDomainId);

    final domainMap = <String, D>{};
    bool invalidDomains = false;
    for (final domainId in persistedDomainIds) {
      OTL.logger?.d('[domain-manager] Restoring domain $domainId');
      final domain = await restoreDomain(domainId);
      if (domain == null) {
        OTL.logger
            ?.e('[domain-manager] Domain $domainId is invalid. Deleting.');
        invalidDomains = true;
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
      _persist.put(_persistKeyCurrentDomainId, currentDomainId);
    }

    final currentDomain = domainMap[_persist.get(_persistKeyCurrentDomainId)];

    state = DomainManagerState(Map.unmodifiable(domainMap), currentDomain);
  }

  /// Add a [Domain] to the list of logged-in domains
  void addDomain(D domain) async {
    if (!state.domainMap.containsKey(domain.id)) {
      final domainMap = Map.of(state.domainMap);
      domainMap[domain.id] = domain;
      _persist.put(
          _persistKeyDomainIds, domainMap.keys.toList(growable: false));

      final currentDomain = state.currentDomain ?? domain;
      if (currentDomain != state.currentDomain) {
        _persist.put(_persistKeyCurrentDomainId, currentDomain.id);
      }
      state = DomainManagerState(Map.unmodifiable(domainMap), currentDomain);
    }
  }

  /// Remove a [Domain] from the list of logged-in domains, and perform cleanup
  FutureOr<void> removeDomain(String domainId) {
    final domainMap = Map.of(state.domainMap);
    final removed = domainMap.remove(domainId);
    if (removed != null) {
      _persist.put(
          _persistKeyDomainIds, domainMap.keys.toList(growable: false));

      final currentDomain = state.currentDomain?.id == domainId
          ? (domainMap.isEmpty ? null : domainMap.values.first)
          : state.currentDomain;

      if (currentDomain != state.currentDomain) {
        _persist.put(_persistKeyCurrentDomainId, currentDomain?.id);
      }
      state = DomainManagerState(Map.unmodifiable(domainMap), currentDomain);
      return removed.delete();
    }
  }
}
