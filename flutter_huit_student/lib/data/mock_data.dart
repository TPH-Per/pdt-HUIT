import 'models.dart';

// ──────────────────────────────────────────────
//  Mock data for HUIT Academic Affairs (Phòng Đào Tạo)
// ──────────────────────────────────────────────

const List<Specialty> mockSpecialties = [
  Specialty(
      id: 1,
      name: 'Đăng ký học phần',
      description: 'Đăng ký, thêm, bớt học phần theo học kỳ'),
  Specialty(
      id: 2,
      name: 'Bảng điểm & Học bạ',
      description: 'Xin cấp bảng điểm, học bạ, xác nhận kết quả học tập'),
  Specialty(
      id: 3,
      name: 'Bằng & Chứng chỉ',
      description: 'Nhận bằng tốt nghiệp, chứng chỉ, xác nhận tốt nghiệp'),
  Specialty(
      id: 4,
      name: 'Giấy tờ xác nhận',
      description: 'Xác nhận sinh viên, giấy giới thiệu thực tập'),
  Specialty(
      id: 5,
      name: 'Chuyển ngành / Khoa',
      description: 'Xét duyệt chuyển ngành, chuyển khoa'),
  Specialty(
      id: 6,
      name: 'Miễn giảm học phí',
      description: 'Nộp hồ sơ xét miễn giảm học phí, học bổng'),
  Specialty(
      id: 7,
      name: 'Tạm dừng học tập',
      description: 'Nghỉ học tạm thời, bảo lưu kết quả học tập'),
  Specialty(
      id: 8,
      name: 'Khiếu nại điểm',
      description: 'Xem xét phúc khảo điểm thi, điểm quá trình'),
];

const List<Procedure> mockProcedures = [
  Procedure(
    id: 101,
    code: 'DT-001',
    name: 'Xin cấp bảng điểm (tiếng Việt)',
    description: 'Bảng điểm toàn khóa học dùng cho xin việc, học bổng',
    processingDays: 3,
    requiredDocuments: [
      'Đơn xin cấp bảng điểm (mẫu phòng ĐT)',
      'Bản sao thẻ sinh viên',
      'Biên lai nộp lệ phí'
    ],
  ),
  Procedure(
    id: 102,
    code: 'DT-002',
    name: 'Xin cấp bảng điểm (tiếng Anh)',
    description: 'Bảng điểm toàn khóa học bằng Tiếng Anh',
    processingDays: 5,
    requiredDocuments: [
      'Đơn xin cấp bảng điểm (mẫu phòng ĐT)',
      'Bản sao thẻ sinh viên',
      'Biên lai nộp lệ phí'
    ],
  ),
  Procedure(
    id: 103,
    code: 'DT-003',
    name: 'Xác nhận sinh viên đang học',
    description: 'Giấy xác nhận đang là sinh viên HUIT',
    processingDays: 1,
    requiredDocuments: ['Đơn xin xác nhận', 'Nêu rõ mục đích sử dụng'],
  ),
  Procedure(
    id: 104,
    code: 'DT-004',
    name: 'Giấy giới thiệu thực tập',
    description: 'Giấy giới thiệu đến cơ sở để thực tập chuyên ngành',
    processingDays: 2,
    requiredDocuments: [
      'Đơn xin giấy giới thiệu',
      'Thông tin nơi thực tập',
      'Xác nhận của đơn vị tiếp nhận'
    ],
  ),
  Procedure(
    id: 105,
    code: 'DT-005',
    name: 'Đăng ký học lại / học cải thiện',
    description: 'Nộp đơn đăng ký học lại học phần đạt điểm D/F',
    processingDays: 2,
    requiredDocuments: ['Đơn đăng ký học lại', 'Bảng điểm học kỳ gần nhất'],
  ),
  Procedure(
    id: 106,
    code: 'DT-006',
    name: 'Chứng nhận tốt nghiệp tạm thời',
    description: 'Giấy chứng nhận đã hoàn thành chương trình đào tạo',
    processingDays: 3,
    requiredDocuments: ['Đơn xin chứng nhận', 'Bản photo thẻ sinh viên'],
  ),
];

const List<Appointment> mockAppointments = [
  Appointment(
    id: 1,
    code: 'APT-2026-001',
    queueDisplay: 'A058',
    appointmentDate: '25/02/2026',
    appointmentTime: '09:30',
    procedureName: 'Xin cấp bảng điểm (tiếng Việt)',
    status: 'waiting',
  ),
  Appointment(
    id: 2,
    code: 'APT-2026-002',
    queueDisplay: 'B012',
    appointmentDate: '28/02/2026',
    appointmentTime: '10:00',
    procedureName: 'Xác nhận sinh viên đang học',
    status: 'upcoming',
  ),
  Appointment(
    id: 3,
    code: 'APT-2025-150',
    queueDisplay: 'C005',
    appointmentDate: '15/11/2025',
    appointmentTime: '14:00',
    procedureName: 'Giấy giới thiệu thực tập',
    status: 'completed',
  ),
  Appointment(
    id: 4,
    code: 'APT-2025-099',
    queueDisplay: 'A099',
    appointmentDate: '20/10/2025',
    appointmentTime: '08:30',
    procedureName: 'Đăng ký học lại / học cải thiện',
    status: 'cancelled',
  ),
];

const List<AppDocument> mockDocuments = [
  AppDocument(
    id: 'DOC001',
    name: 'Bảng điểm khóa 2021-2025.pdf',
    type: 'PDF',
    size: '1.8 MB',
    date: '15/01/2026',
    status: 'verified',
    category: 'Academic',
  ),
  AppDocument(
    id: 'DOC002',
    name: 'Thẻ sinh viên.jpg',
    type: 'IMG',
    size: '520 KB',
    date: '10/09/2025',
    status: 'verified',
    category: 'Personal',
  ),
  AppDocument(
    id: 'DOC003',
    name: 'Đơn xin học bổng.docx',
    type: 'DOC',
    size: '340 KB',
    date: '20/01/2026',
    status: 'pending',
    category: 'Forms',
  ),
  AppDocument(
    id: 'DOC004',
    name: 'Xác nhận sinh viên (11/2025).pdf',
    type: 'PDF',
    size: '256 KB',
    date: '05/11/2025',
    status: 'verified',
    category: 'Academic',
  ),
  AppDocument(
    id: 'DOC005',
    name: 'Hóa đơn học phí HK1_2025.pdf',
    type: 'PDF',
    size: '410 KB',
    date: '25/08/2025',
    status: 'rejected',
    category: 'Personal',
  ),
];

const List<FeedbackItem> mockFeedbackHistory = [
  FeedbackItem(
    id: 1,
    title: 'Thái độ phục vụ rất nhiệt tình',
    content:
        'Nhân viên cửa 3 hướng dẫn chi tiết, tận tình khi tôi nộp đơn xin bảng điểm.',
    date: '15/01/2026',
    status: 'replied',
    type: 1,
    reply:
        'Cảm ơn bạn đã chia sẻ! Chúng tôi sẽ biểu dương nhân viên và tiếp tục duy trì chất lượng phục vụ.',
  ),
  FeedbackItem(
    id: 2,
    title: 'Hệ thống đặt lịch bị lỗi sáng nay',
    content: 'Tôi không thể chọn ngày trong tháng 2 khi đặt lịch trên app.',
    date: '20/01/2026',
    status: 'pending',
    type: 0,
  ),
  FeedbackItem(
    id: 3,
    title: 'Thời gian chờ quá lâu',
    content:
        'Mặc dù đã đặt lịch, tôi vẫn phải chờ hơn 1 tiếng tại phòng đào tạo.',
    date: '10/12/2025',
    status: 'replied',
    type: 0,
    reply:
        'Chúng tôi đã ghi nhận và sẽ điều chỉnh năng lực tiếp nhận hồ sơ để giảm thời gian chờ.',
  ),
];

const List<Map<String, String>> mockNews = [
  {
    'title': 'Lịch đăng ký học phần HK2 năm học 2025-2026',
    'summary':
        'Phòng Đào Tạo thông báo sinh viên đăng ký học phần từ 08h00 ngày 25/02/2026.',
    'date': '1 ngày trước',
    'image': 'https://huit.edu.vn/images/banners/banner1.jpg',
  },
  {
    'title': 'Khai giảng lớp Kỹ năng mềm HK2/2025-2026',
    'summary':
        'Lớp học kỹ năng giao tiếp và làm việc nhóm dành cho sinh viên năm 1, 2.',
    'date': '3 ngày trước',
    'image': '',
  },
  {
    'title': 'Thông báo nộp học phí HK2 năm học 2025-2026',
    'summary':
        'Sinh viên nộp học phí trước ngày 01/03/2026 để tránh bị khóa tài khoản.',
    'date': '5 ngày trước',
    'image': '',
  },
];
