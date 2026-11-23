class JobEntity {
  final int? id;
  final String title;
  final String department;
  final String description;
  final String status;
  final String approval;
  final int? createdBy;
  final String? createdOn;
  final int? approvedBy;
  final String? approvedOn;
  final String? rejectReason;
  final int? cands;
  final String? creatorName;

  const JobEntity({
    this.id,
    required this.title,
    required this.department,
    required this.description,
    this.status = 'Open',
    this.approval = 'Pending',
    this.createdBy,
    this.createdOn,
    this.approvedBy,
    this.approvedOn,
    this.rejectReason,
    this.cands,
    this.creatorName,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'department': department,
        'description': description,
        'status': status,
        'approval': approval,
        'created_by': createdBy,
        'created_on': createdOn,
        'approved_by': approvedBy,
        'approved_on': approvedOn,
        'reject_reason': rejectReason,
        if (cands != null) 'cands': cands,
        if (creatorName != null) 'creator_name': creatorName,
      };

  factory JobEntity.fromMap(Map<String, Object?> map) => JobEntity(
        id: map['id'] as int?,
        title: (map['title'] ?? '').toString(),
        department: (map['department'] ?? '').toString(),
        description: (map['description'] ?? '').toString(),
        status: (map['status'] ?? 'Open').toString(),
        approval: (map['approval'] ?? 'Pending').toString(),
        createdBy: map['created_by'] as int?,
        createdOn: map['created_on']?.toString(),
        approvedBy: map['approved_by'] as int?,
        approvedOn: map['approved_on']?.toString(),
        rejectReason: map['reject_reason']?.toString(),
        cands: (map['cands'] as num?)?.toInt(),
        creatorName: map['creator_name']?.toString(),
      );

  Object? operator [](String key) => toMap()[key];
  String s(String key, [String def = '']) => toMap()[key]?.toString() ?? def;
  int? i(String key) {
    final val = toMap()[key];
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '');
  }
  double d(String key, [double def = 0.0]) {
    final val = toMap()[key];
    if (val is double) return val;
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '') ?? def;
  }
}

class CandidateEntity {
  final int? id;
  final int jobId;
  final String name;
  final String email;
  final String phone;
  final String stage;
  final int rating;
  final String source;
  final double expectedSalary;
  final double experienceYears;
  final String currentCompany;
  final String appliedOn;
  final String notes;
  final String? resumePath;
  final int? convertedEmployeeId;
  final String? jobTitle;
  final String? jobDepartment;
  final String? nextInterview;

  const CandidateEntity({
    this.id,
    required this.jobId,
    required this.name,
    required this.email,
    required this.phone,
    this.stage = 'Applied',
    this.rating = 0,
    required this.source,
    this.expectedSalary = 0,
    this.experienceYears = 0,
    this.currentCompany = '',
    required this.appliedOn,
    this.notes = '',
    this.resumePath,
    this.convertedEmployeeId,
    this.jobTitle,
    this.jobDepartment,
    this.nextInterview,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'job_id': jobId,
        'name': name,
        'email': email,
        'phone': phone,
        'stage': stage,
        'rating': rating,
        'source': source,
        'expected_salary': expectedSalary,
        'experience_years': experienceYears,
        'current_company': currentCompany,
        'applied_on': appliedOn,
        'notes': notes,
        'resume_path': resumePath,
        'converted_employee_id': convertedEmployeeId,
        if (jobTitle != null) 'job_title': jobTitle,
        if (jobDepartment != null) 'job_department': jobDepartment,
        if (nextInterview != null) 'next_interview': nextInterview,
      };

  factory CandidateEntity.fromMap(Map<String, Object?> map) => CandidateEntity(
        id: map['id'] as int?,
        jobId: (map['job_id'] as num?)?.toInt() ?? 0,
        name: (map['name'] ?? '').toString(),
        email: (map['email'] ?? '').toString(),
        phone: (map['phone'] ?? '').toString(),
        stage: (map['stage'] ?? 'Applied').toString(),
        rating: (map['rating'] as num?)?.toInt() ?? 0,
        source: (map['source'] ?? '').toString(),
        expectedSalary: (map['expected_salary'] as num?)?.toDouble() ?? 0,
        experienceYears: (map['experience_years'] as num?)?.toDouble() ?? 0,
        currentCompany: (map['current_company'] ?? '').toString(),
        appliedOn: (map['applied_on'] ?? '').toString(),
        notes: (map['notes'] ?? '').toString(),
        resumePath: map['resume_path']?.toString(),
        convertedEmployeeId: map['converted_employee_id'] as int?,
        jobTitle: map['job_title']?.toString(),
        jobDepartment: map['job_department']?.toString(),
        nextInterview: map['next_interview']?.toString(),
      );

  Object? operator [](String key) => toMap()[key];
  String s(String key, [String def = '']) => toMap()[key]?.toString() ?? def;
  int? i(String key) {
    final val = toMap()[key];
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '');
  }
  double d(String key, [double def = 0.0]) {
    final val = toMap()[key];
    if (val is double) return val;
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '') ?? def;
  }
}

class InterviewEntity {
  final int? id;
  final int candidateId;
  final int interviewerId;
  final String round;
  final String scheduledAt;
  final String result;
  final String feedback;
  final String? candName;
  final String? jobTitle;
  final String? interviewerName;

  const InterviewEntity({
    this.id,
    required this.candidateId,
    required this.interviewerId,
    required this.round,
    required this.scheduledAt,
    this.result = 'Scheduled',
    this.feedback = '',
    this.candName,
    this.jobTitle,
    this.interviewerName,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'candidate_id': candidateId,
        'interviewer_id': interviewerId,
        'round': round,
        'scheduled_at': scheduledAt,
        'result': result,
        'feedback': feedback,
        if (candName != null) 'cand_name': candName,
        if (jobTitle != null) 'job_title': jobTitle,
        if (interviewerName != null) 'interviewer_name': interviewerName,
      };

  factory InterviewEntity.fromMap(Map<String, Object?> map) => InterviewEntity(
        id: map['id'] as int?,
        candidateId: (map['candidate_id'] as num?)?.toInt() ?? 0,
        interviewerId: (map['interviewer_id'] as num?)?.toInt() ?? 0,
        round: (map['round'] ?? '').toString(),
        scheduledAt: (map['scheduled_at'] ?? '').toString(),
        result: (map['result'] ?? 'Scheduled').toString(),
        feedback: (map['feedback'] ?? '').toString(),
        candName: map['cand_name']?.toString(),
        jobTitle: map['job_title']?.toString(),
        interviewerName: map['interviewer_name']?.toString(),
      );

  Object? operator [](String key) => toMap()[key];
  String s(String key, [String def = '']) => toMap()[key]?.toString() ?? def;
  int? i(String key) {
    final val = toMap()[key];
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '');
  }
  double d(String key, [double def = 0.0]) {
    final val = toMap()[key];
    if (val is double) return val;
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '') ?? def;
  }
}
