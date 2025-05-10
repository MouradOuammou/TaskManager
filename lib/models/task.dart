class Task {
  final String title;
  final DateTime? dueDate;
  bool isCompleted;

  Task({
    required this.title,
    this.dueDate,
    this.isCompleted = false,
  });
}