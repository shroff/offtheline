import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'domain.dart';

const _boxName = "domains";
const _persistKeyCurrentDomain = "currentDomain";
const _persistKeyDomainIds = "domains";

abstract class DomainManager<D extends Domain> with ChangeNotifier {
  late final Box _persist;
  final Map<String, D> _domainMap = {};
  final String? userAgent;

  List<String> _domainIdList = List.unmodifiable([]);
  List<String> get domainIdList => _domainIdList;
  set domainIdList(List<String> domainIds) {
    _domainIdList = List.unmodifiable(domainIds);
    _persist.put(_persistKeyDomainIds, domainIds);
  }

  String? get currentDomain => _persist.get(_persistKeyCurrentDomain);
  set currentDomain(String? value) {
    if (value != null && !_domainMap.containsKey(value)) return;
    _persist.put(_persistKeyCurrentDomain, value);
    notifyListeners();
  }

  DomainManager(this.userAgent);

  Future<void> initialize() async {
    _persist = await Hive.openBox(_boxName);
    final List<String> domainIds =
        _persist.get(_persistKeyDomainIds)?.cast<String>() ?? <String>[];
    await Future.wait(domainIds.map((domainId) async {
      debugPrint("Restoring domain $domainId");
      final domain = await restoreDomainInstance(domainId);
      if (domainInstanceValid(domain)) {
        addDomain(domain);
      } else {
        debugPrint("Domain is invalid. Deleting $domainId");
        await clearDomain(domainId);
      }
    }));
    if (!_domainMap.containsKey(currentDomain)) {
      currentDomain = domainIdList.isEmpty ? null : domainIdList[0];
    }
  }

  void addDomain(D domain) async {
    if (!domainIdList.contains(domain.id)) {
      domainIdList = List.from(domainIdList)..add(domain.id);
      domain.api.userAgent = userAgent;
      _domainMap[domain.id] = domain;
      if (currentDomain == null)
        currentDomain = domainIdList.isEmpty ? null : domainIdList[0];
      notifyListeners();
    }
  }

  @protected
  Future<D> restoreDomainInstance(String domainId);

  @protected
  bool domainInstanceValid(D domain) => domain.api.valid;

  FutureOr<void> clearDomain(String domainId) {
    final domain = _domainMap[domainId];
    _domainMap.remove(domainId);
    domainIdList = List.from(domainIdList)..remove(domainId);
    if (currentDomain == domainId)
      currentDomain = domainIdList.isEmpty ? null : domainIdList[0];
    notifyListeners();
    return domain?.delete();
  }

  D? getDomain(String domainId) => _domainMap[domainId];
}
