import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/pg_group.dart';
import '../data/repositories/groups_repository.dart';
import 'repo_providers.dart';

final groupsRepositoryProvider = Provider((ref) => GroupsRepository());

class GroupsNotifier extends AsyncNotifier<List<PgGroup>> {
  @override
  Future<List<PgGroup>> build() async {
    ref.watch(currentUserIdProvider);
    return ref.read(groupsRepositoryProvider).fetchMyGroups();
  }

  Future<PgGroup> create({required String name, String? meetingTime}) async {
    final group = await ref.read(groupsRepositoryProvider).createGroup(name: name, meetingTime: meetingTime);
    ref.invalidateSelf();
    await future;
    return group;
  }

  Future<void> join(String code) async {
    await ref.read(groupsRepositoryProvider).joinGroup(code);
    ref.invalidateSelf();
    await future;
  }

  Future<void> leave(String groupId) async {
    await ref.read(groupsRepositoryProvider).leaveGroup(groupId);
    ref.invalidateSelf();
    await future;
  }
}

final groupsProvider = AsyncNotifierProvider<GroupsNotifier, List<PgGroup>>(GroupsNotifier.new);
