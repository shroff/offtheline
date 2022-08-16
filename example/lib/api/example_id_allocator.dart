import 'package:example/api/api.dart';

const _persistKeyIdBlockSize = 'idBlockSize';
const _persistKeyUsedIds = 'usedIds';
const _persistKeyIdBlocks = 'idBlocks';

class ExampleIdAllocator with AccountHooks<Map<String, dynamic>> {
  late final void Function() removeResponseProcessor;

  @override
  Future<void> initialize(Account<Map<String, dynamic>> account) async {
    super.initialize(account);
    removeResponseProcessor = account.api.addResponseProcessor(processResponse);
  }

  @override
  Future<void> close() async {
    super.close();
    removeResponseProcessor();
  }

  int get idBlockSize => account.getPersisted(_persistKeyIdBlockSize) ?? 0;
  set idBlockSize(int value) {
    assert(account.getPersisted(_persistKeyIdBlockSize) == null);
    account.persist(_persistKeyIdBlockSize, value);
  }

  int get _usedIds => account.getPersisted(_persistKeyUsedIds) ?? 0;
  int get remainingIds =>
      ((account.getPersisted(_persistKeyIdBlocks) ?? const []).length <<
          idBlockSize) -
      _usedIds;

  void processResponse(Map<String, dynamic>? data, dynamic tag) {
    if (data != null && data.containsKey('id_block')) {
      final List<int> blocks =
          account.getPersisted(_persistKeyIdBlocks)?.cast<int>() ?? [];
      blocks.add(data["id_block"]);
      account.persist(_persistKeyIdBlocks, blocks);
    }
  }

  Future<int> generateId() async {
    final List<int> blocks =
        account.getPersisted(_persistKeyIdBlocks)?.cast<int>() ?? [];
    if (blocks.isEmpty) throw Exception('Cannot allocate ID.');
    final usedIds = _usedIds;

    // if (usedIds >= (1 << _gidShift)) throw Exception('No IDs left to allocate');
    final nextId = usedIds | (blocks[0] << idBlockSize);
    if (usedIds >= (1 << idBlockSize)) {
      blocks.removeAt(0);
      await account.persist(_persistKeyIdBlocks, blocks);
      await account.persist(_persistKeyUsedIds, 0);
    } else {
      await account.persist(_persistKeyUsedIds, usedIds + 1);
    }
    return nextId;
  }
}
