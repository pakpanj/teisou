import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/exam_mode.dart';
import '../../data/models/exam_question.dart';

/// Generates a fresh 10-question session per [ExamMode]. Marked
/// `autoDispose` so "Ulangi Ujian" (which pushes a new [ExamScreen]
/// instance) always gets a newly-generated session instead of a stale
/// cached one.
final examQuestionsProvider = FutureProvider.autoDispose
    .family<List<ExamQuestion>, ExamMode>((ref, mode) async {
      final user = await ref.watch(appStartupProvider.future);
      return ref.watch(examRepositoryProvider).generateExam(mode, user.uid);
    });
