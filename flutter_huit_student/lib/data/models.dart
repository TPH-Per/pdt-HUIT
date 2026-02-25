class Specialty {
  final int id;
  final String name;
  final String description;

  const Specialty({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Specialty.fromJson(Map<String, dynamic> json) => Specialty(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
      );
}

class Procedure {
  final int id;
  final String code;
  final String name;
  final String description;
  final int processingDays;
  final List<String> requiredDocuments;

  const Procedure({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.processingDays,
    required this.requiredDocuments,
  });

  factory Procedure.fromJson(Map<String, dynamic> json) => Procedure(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        processingDays: json['processingDays'] as int? ?? 1,
        requiredDocuments: (json['requiredDocuments'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class TimeSlot {
  final String time;
  final int available;
  final int maxCapacity;

  const TimeSlot({
    required this.time,
    required this.available,
    required this.maxCapacity,
  });

  bool get isFull => available <= 0;

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        time: json['time'] as String,
        available: json['available'] as int? ?? 0,
        maxCapacity: json['maxCapacity'] as int? ?? 30,
      );
}

class Appointment {
  final int? id;
  final String code;
  final String queueDisplay;
  final String appointmentDate;
  final String appointmentTime;
  final String procedureName;
  final String status;
  final bool zaloLinked;
  final int? peopleAhead;
  final String? currentServing;
  final String? counterName;

  const Appointment({
    this.id,
    required this.code,
    required this.queueDisplay,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.procedureName,
    required this.status,
    this.zaloLinked = false,
    this.peopleAhead,
    this.currentServing,
    this.counterName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as int?,
        code: json['code'] as String? ?? '',
        queueDisplay: json['queueDisplay'] as String? ?? '',
        appointmentDate: json['appointmentDate'] as String? ?? '',
        appointmentTime: json['appointmentTime'] as String? ?? '',
        procedureName:
            (json['serviceName'] ?? json['procedureName']) as String? ??
                'Dịch vụ học vụ',
        status: json['status'] as String? ?? 'upcoming',
        zaloLinked: json['zaloLinked'] as bool? ?? false,
        peopleAhead: json['peopleAhead'] as int?,
        currentServing: json['currentServing'] as String?,
        counterName: json['counterName'] as String?,
      );

  String get normalizedStatus {
    final s = status.toLowerCase();
    if (['pending', 'scheduled', 'upcoming'].contains(s)) return 'upcoming';
    if (['in_queue', 'waiting', 'received', 'supplement'].contains(s))
      return 'waiting';
    if (['processing'].contains(s)) return 'processing';
    if (['completed'].contains(s)) return 'completed';
    if (['cancelled'].contains(s)) return 'cancelled';
    return s;
  }

  String get statusLabel {
    switch (normalizedStatus) {
      case 'upcoming':
        return 'Sắp tới';
      case 'waiting':
        return 'Đang chờ';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã huỷ';
      default:
        return status;
    }
  }

  bool get isActive =>
      ['upcoming', 'waiting', 'processing'].contains(normalizedStatus);
}

class AppDocument {
  final String id;
  final String name;
  final String type;
  final String size;
  final String date;
  final String status; // verified, pending, rejected
  final String category; // Personal, Academic, Forms

  const AppDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.date,
    required this.status,
    required this.category,
  });

  String get statusLabel {
    switch (status) {
      case 'verified':
        return 'Đã xác nhận';
      case 'pending':
        return 'Chờ duyệt';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return status;
    }
  }
}

class FeedbackItem {
  final int id;
  final String title;
  final String content;
  final String date;
  final String status; // replied, pending
  final String? reply;
  final int type;

  const FeedbackItem({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.status,
    required this.type,
    this.reply,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    String parsedStatus = 'pending';
    if (json['status'] == 2) {
      parsedStatus = 'replied';
    }

    return FeedbackItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Góp ý',
      content: json['content'] as String? ?? '',
      date: json['createdAt']?.toString().split('T')[0] ?? '',
      status: parsedStatus,
      type: json['type'] as int? ?? 0,
      reply: json['reply'] as String?,
    );
  }
}
