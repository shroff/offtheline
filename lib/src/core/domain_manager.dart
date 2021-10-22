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
    if (!_domainMap.containsKey(value)) return;
    _persist.put(_persistKeyCurrentDomain, value);
    notifyListeners();
  }

  DomainManager(this.userAgent);

  Future<void> initialize() async {
    _persist = await Hive.openBox(_boxName);
    final domainIds =
        _persist.get(_persistKeyDomainIds)?.cast<String>() ?? <String>[];
    domainIdList = domainIds;
    final domains = await Future.wait(
        domainIdList.map((domainId) => createDomain(domainId)));
    addDomains(domains.where((domain) => domain != null).cast<D>());
  }

  Future<D?> createDomain(String domainId);

  void addDomains(Iterable<D> domains) {
    domains.forEach((domain) {
      domain.api.userAgent = userAgent;
      if (!_domainMap.containsKey(domain.id)) {
        domainIdList = List.from(domainIdList)..add(domain.id);
        _domainMap[domain.id] = domain;
      }
    });
    if (currentDomain == null)
      currentDomain = domainIdList.isEmpty ? null : domainIdList[0];
    notifyListeners();
  }

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
