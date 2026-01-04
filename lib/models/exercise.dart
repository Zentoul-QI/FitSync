class Exercise {
  final String name;
  final String description;
  final int reps;
  final String exerciseType;

  Exercise({
    required this.name,
    required this.description,
    required this.reps,
    required this.exerciseType,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'reps': reps,
      'exerciseType': exerciseType,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      description: json['description'] as String,
      reps: json['reps'] as int,
      exerciseType: json['exerciseType'] as String,
    );
  }
}