class Course {
  final int? id;
  final String? ownerId;
  final String title;
  final String code;
  final int credits;
  final String status;

  const Course({
    this.id,
    this.ownerId,
    required this.title,
    required this.code,
    required this.credits,
    required this.status,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int?,
      ownerId: json['owner_id'] as String?,
      title: (json['title'] ?? '') as String,
      code: (json['code'] ?? '') as String,
      credits: (json['credits'] ?? 0) as int,
      status: (json['status'] ?? 'Aktif') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      'title': title,
      'code': code,
      'credits': credits,
      'status': status,
    };
  }
}
