
class GoalEntity {
  final int? id;
  final int employeeId;
  final String title;
  final String description;
  final String dueDate;
  final int progress;
  final String status;
  final String? empName;

  const GoalEntity({
    this.id,
    required this.employeeId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.progress = 0,
    this.status = 'Pending',
    this.empName,
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'employee_id': employeeId,
    'title': title,
    'description': description,
    'due_date': dueDate,
    'progress': progress,
    'status': status,
  };

  factory GoalEntity.fromMap(Map<String, Object?> map) {
    return GoalEntity(
      id: (map['id'] as num?)?.toInt(),
      employeeId: (map['employee_id'] as num?)?.toInt() ?? 0,
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      dueDate: (map['due_date'] ?? '').toString(),
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? 'Pending').toString(),
      empName: map['emp_name']?.toString(),
    );
  }
}

class ReviewEntity {
  final int? id;
  final int employeeId;
  final int reviewerId;
  final String period;
  final int rating;
  final String strengths;
  final String improvements;
  final String comments;
  final String createdOn;
  final String? empName;
  final String? reviewerName;

  const ReviewEntity({
    this.id,
    required this.employeeId,
    required this.reviewerId,
    required this.period,
    required this.rating,
    this.strengths = '',
    this.improvements = '',
    required this.comments,
    required this.createdOn,
    this.empName,
    this.reviewerName,
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'employee_id': employeeId,
    'reviewer_id': reviewerId,
    'period': period,
    'rating': rating,
    'strengths': strengths,
    'improvements': improvements,
    'comments': comments,
    'created_on': createdOn,
  };

  factory ReviewEntity.fromMap(Map<String, Object?> map) {
    return ReviewEntity(
      id: (map['id'] as num?)?.toInt(),
      employeeId: (map['employee_id'] as num?)?.toInt() ?? 0,
      reviewerId: (map['reviewer_id'] as num?)?.toInt() ?? 0,
      period: (map['period'] ?? '').toString(),
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      strengths: (map['strengths'] ?? '').toString(),
      improvements: (map['improvements'] ?? '').toString(),
      comments: (map['comments'] ?? '').toString(),
      createdOn: (map['created_on'] ?? '').toString(),
      empName: map['emp_name']?.toString(),
      reviewerName: map['reviewer_name']?.toString(),
    );
  }
}
