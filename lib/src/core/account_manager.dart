import 'dart:async';

import 'package:hive/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:state_notifier/state_notifier.dart';

const _boxName = 'account_manager';
const _persistKeySelectedAccountId = 'selectedAccountId';
const _persistKeyAccountIds = 'accountIds';

class AccountManagerState<R extends ApiResponse, A extends Account<R>> {
  final Map<String, A> accounts;
  final A? selectedAccount;

  const AccountManagerState(this.accounts, this.selectedAccount);
}

/// Maintain a list of logged-in [Account]s
class AccountManager<R extends ApiResponse, A extends Account<R>>
    extends StateNotifier<AccountManagerState<R, A>> with LocatorMixin {
  final FutureOr<A?> Function(String accountId) restoreAccount;
  late final Box _persist;

  AccountManager._(this.restoreAccount)
      : super(const AccountManagerState({}, null));

  /// Restore this instance and all managed [Account]s from persistance
  static Future<AccountManager<R, A>>
      restore<T, R extends ApiResponse, A extends Account<R>>(
    FutureOr<A?> Function(String accountId) restoreAccount,
  ) async {
    final accountManager = AccountManager<R, A>._(restoreAccount);
    await accountManager._initialize();
    return accountManager;
  }

  Future<void> _initialize() async {
    _persist = await Hive.openBox(_boxName);
    final List<String> persistedAccountIds =
        _persist.get(_persistKeyAccountIds)?.cast<String>() ?? <String>[];
    String? selectedAccountId = _persist.get(_persistKeySelectedAccountId);

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

    bool invalidCurrentAccount = false;
    if (selectedAccountId == null && accounts.isNotEmpty) {
      invalidCurrentAccount = true;
      selectedAccountId = accounts.keys.first;
    } else if (selectedAccountId != null &&
        !accounts.containsKey(selectedAccountId)) {
      selectedAccountId = accounts.isEmpty ? null : accounts.keys.first;
    }
    if (invalidCurrentAccount) {
      _persist.put(_persistKeySelectedAccountId, selectedAccountId);
    }

    final currentAccount = accounts[_persist.get(_persistKeySelectedAccountId)];

    state = AccountManagerState(Map.unmodifiable(accounts), currentAccount);
  }

  /// Add an [Account] to the list of logged-in accounts
  void addAccount(A account) async {
    if (!state.accounts.containsKey(account.id)) {
      final accounts = Map.of(state.accounts);
      accounts[account.id] = account;
      _persist.put(
          _persistKeyAccountIds, accounts.keys.toList(growable: false));

      final currentAccount = state.selectedAccount ?? account;
      if (currentAccount != state.selectedAccount) {
        _persist.put(_persistKeySelectedAccountId, currentAccount.id);
      }
      state = AccountManagerState(Map.unmodifiable(accounts), currentAccount);
    }
  }

  /// Remove an [Account] from the list of logged-in accounts, and perform cleanup
  FutureOr<void> removeAccount(String accountId) {
    final accounts = Map.of(state.accounts);
    final removed = accounts.remove(accountId);
    if (removed != null) {
      _persist.put(
          _persistKeyAccountIds, accounts.keys.toList(growable: false));

      final currentAccount = state.selectedAccount?.id == accountId
          ? (accounts.isEmpty ? null : accounts.values.first)
          : state.selectedAccount;

      if (currentAccount != state.selectedAccount) {
        _persist.put(_persistKeySelectedAccountId, currentAccount?.id);
      }
      state = AccountManagerState(Map.unmodifiable(accounts), currentAccount);
      return removed.delete();
    }
  }
}
