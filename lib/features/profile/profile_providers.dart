import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/exam_result.dart';

final recentExamHistoryProvider = StreamProvider<List<ExamResult>>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(examRepositoryProvider).watchRecentHistory(user.uid, limit: 3);
});
