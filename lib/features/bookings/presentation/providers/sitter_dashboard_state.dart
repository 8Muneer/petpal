import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/care_task.dart';

class SitterDashboardState {
  final List<CareTask> activeChecklist;
  final DateTime? startTime;
  final bool isLive;

  SitterDashboardState({
    this.activeChecklist = const [],
    this.startTime,
    this.isLive = false,
  });

  SitterDashboardState copyWith({
    List<CareTask>? activeChecklist,
    DateTime? startTime,
    bool? isLive,
  }) {
    return SitterDashboardState(
      activeChecklist: activeChecklist ?? this.activeChecklist,
      startTime: startTime ?? this.startTime,
      isLive: isLive ?? this.isLive,
    );
  }
}

class SitterDashboardNotifier extends StateNotifier<SitterDashboardState> {
  SitterDashboardNotifier() : super(SitterDashboardState(
    activeChecklist: [
      const CareTask(id: 'food', label: 'אוכל ומים', type: CareTaskType.food),
      const CareTask(id: 'walk', label: 'טיול בוקר', type: CareTaskType.walk),
      const CareTask(id: 'meds', label: 'תרופות', type: CareTaskType.meds),
    ],
    startTime: DateTime.now().subtract(const Duration(hours: 14, minutes: 22)),
    isLive: true,
  ));

  void toggleTask(String taskId) {
    state = state.copyWith(
      activeChecklist: state.activeChecklist.map((task) {
        if (task.id == taskId) {
          return task.copyWith(
            isDone: !task.isDone,
            completedAt: !task.isDone ? DateTime.now() : null,
          );
        }
        return task;
      }).toList(),
    );
  }
}

final sitterDashboardProvider = StateNotifierProvider<SitterDashboardNotifier, SitterDashboardState>((ref) {
  return SitterDashboardNotifier();
});
