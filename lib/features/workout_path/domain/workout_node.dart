class WorkoutNode {
  final String id;
  final String title;
  final String videoUrl;
  final bool isCompleted;
  final bool isLocked;

  const WorkoutNode({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.isCompleted = false,
    this.isLocked = true,
  });

  WorkoutNode copyWith({bool? isCompleted, bool? isLocked}) {
    return WorkoutNode(
      id: id,
      title: title,
      videoUrl: videoUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
