import 'dart:async';

import 'package:hive/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:state_notifier/state_notifier.dart';

const _boxName = 'account_manager';
const _persistKeySelectedAccountId = 'selectedAccountId';
const _persistKeyAccountIds = 'accountIds';

class AccountManagerState<A extends Account> {
  final Map<String, A> accounts;
  final A? selectedAccount;

  const AccountManagerState(this.accounts, this.selectedAccount);
}

/// Maintain a list of logged-in [Account]s
class AccountManager<A extends Account>
    extends StateNotifier<AccountManagerState<A>> with LocatorMixin {
  final FutureOr<A?> Function(String accountId) restoreAccount;
  late final Box _persist;

  AccountManager._(this.restoreAccount)
      : super(const AccountManagerState({}, null));

  /// Restore this instance and all managed [Account]s from persistance
  static Future<AccountManager<D>> restore<D extends Account>(
    FutureOr<D?> Function(String accountId) restoreAccount,
  ) async {
    final accountManager = AccountManager._(restoreAccount);
    await accountManager._initialize();
    return accountManager;
  }

  Future<void> _initialize() async {
    _persist = await Hive.openBox(_boxName);
    final List<String> persistedAccountIds =
        _persist.get(_persistKeyAccountIds)?.cast<String>() ?? <String>[];
    String? currentDomainId = _persist.get(_persistKeySelectedAccountId);

    final accounts = <String, A>{};
    bool invalidAccounts = false;
    for (final accountId in persistedAccountIds) {
      OTL.logger?.d('[account-manager] Restoring account $accountId');
      final account = await restoreAccount(accountId);
      if (account == null) {
        OTL.logger
            ?.e('[account-manager] Account $accountId is invalid. Deleting.');
        invalidAccounts = true;
      } else {
        accounts[accountId] = account;
      }
    }
    if (invalidAccounts) {
      _persist.put(
          _persistKeyAccountIds, accounts.keys.toList(growable: false));
    }

    bool invalidCurrentDomain = false;
    if (currentDomainId == null && accounts.isNotEmpty) {
      invalidCurrentDomain = true;
      currentDomainId = accounts.keys.first;
    } else if (currentDomainId != null &&
        !accounts.containsKey(currentDomainId)) {
      currentDomainId = accounts.isEmpty ? null : accounts.keys.first;
    }
    if (invalidCurrentDomain) {
      _persist.put(_persistKeySelectedAccountId, currentDomainId);
    }

    final currentDomain = accounts[_persist.get(_persistKeySelectedAccountId)];

    state = AccountManagerState(Map.unmodifiable(accounts), currentDomain);
  }

  /// Add an [Account] to the list of logged-in accounts
  void addAccount(A account) async {
    if (!state.accounts.containsKey(account.id)) {
      final accounts = Map.of(state.accounts);
      accounts[account.id] = account;
      _persist.put(
          _persistKeyAccountIds, accounts.keys.toList(growable: false));

      final currentDomain = state.selectedAccount ?? account;
      if (currentDomain != state.selectedAccount) {
        _persist.put(_persistKeySelectedAccountId, currentDomain.id);
      }
      state = AccountManagerState(Map.unmodifiable(accounts), currentDomain);
    }
  }

  /// Remove an [Account] from the list of logged-in accounts, and perform cleanup
  FutureOr<void> removeDomain(String accountId) {
    final accounts = Map.of(state.accounts);
    final removed = accounts.remove(accountId);
    if (removed != null) {
      _persist.put(
          _persistKeyAccountIds, accounts.keys.toList(growable: false));

      final currentDomain = state.selectedAccount?.id == accountId
          ? (accounts.isEmpty ? null : accounts.values.first)
          : state.selectedAccount;

      if (currentDomain != state.selectedAccount) {
        _persist.put(_persistKeySelectedAccountId, currentDomain?.id);
      }
      state = AccountManagerState(Map.unmodifiable(accounts), currentDomain);
      return removed.delete();
    }
  }
}
