class Rule {
  final int? id;
  final String name;
  final int durationMinutes;
  final DateTime createdAt;
  final bool isCompleted;
  final bool isViolated;
  final List<int> activeDays; // 0 = Senin, 6 = Minggu

  Rule({
    this.id,
    required this.name,
    required this.durationMinutes,
    required this.createdAt,
    this.isCompleted = false,
    this.isViolated = false,
    this.activeDays = const [],
  });

  // Untuk menyimpan ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'durationMinutes': durationMinutes,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'isViolated': isViolated ? 1 : 0,
      'activeDays': activeDays.join(','), // disimpan dalam format "0,1,3"
    };
  }

  // Untuk mengambil dari database
  factory Rule.fromMap(Map<String, dynamic> map) {
    return Rule(
      id: map['id'],
      name: map['name'],
      durationMinutes: map['durationMinutes'],
      createdAt: DateTime.parse(map['createdAt']),
      isCompleted: map['isCompleted'] == 1,
      isViolated: map['isViolated'] == 1,
      activeDays:
          (map['activeDays'] != null && map['activeDays'] != '')
              ? (map['activeDays'] as String)
                  .split(',')
                  .map((e) => int.parse(e))
                  .toList()
              : [],
    );
  }

  // Untuk menyalin Rule dengan perubahan tertentu
  Rule copyWith({
    int? id,
    String? name,
    int? durationMinutes,
    DateTime? createdAt,
    bool? isCompleted,
    bool? isViolated,
    List<int>? activeDays,
  }) {
    return Rule(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isViolated: isViolated ?? this.isViolated,
      activeDays: activeDays ?? this.activeDays,
    );
  }
}
