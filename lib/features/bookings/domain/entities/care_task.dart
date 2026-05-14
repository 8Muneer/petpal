
enum CareTaskType { food, walk, meds, custom }

class CareTask {
  final String id;
  final String label;
  final CareTaskType type;
  final bool isDone;
  final DateTime? completedAt;

  const CareTask({
    required this.id,
    required this.label,
    required this.type,
    this.isDone = false,
    this.completedAt,
  });

  CareTask copyWith({bool? isDone, DateTime? completedAt}) {
    return CareTask(
      id: id,
      label: label,
      type: type,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
