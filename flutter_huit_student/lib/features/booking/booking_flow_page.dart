import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/app_state.dart';
import '../../data/models.dart';
import '../../data/mock_data.dart';
import '../../data/api_service.dart';
import '../../shared/widgets/huit_app_bar.dart';
import '../../shared/widgets/huit_button.dart';

class BookingFlowPage extends StatefulWidget {
  const BookingFlowPage({super.key});

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage> {
  final _api = ApiService();
  int _step = 1; // 1=Specialty, 2=Procedure, 3=DateTime, 4=Confirm, 5=Success

  // Selections
  Specialty? _specialty;
  Procedure? _procedure;
  DateTime? _date;
  String? _time;

  // Data
  List<Specialty> _specialties = List.of(mockSpecialties);
  List<Procedure> _procedures = List.of(mockProcedures);
  List<TimeSlot> _slots = [];

  bool _loading = false;
  bool _booking = false;
  Appointment? _booked;

  String _searchTerm = '';

  // Fixed available dates (next 14 days, skip weekends)
  late final List<DateTime> _availableDates;

  @override
  void initState() {
    super.initState();
    _availableDates = _generateDates();
    _loadSpecialties();
  }

  List<DateTime> _generateDates() {
    final dates = <DateTime>[];
    var day = DateTime.now().add(const Duration(days: 1));
    while (dates.length < 14) {
      if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
        dates.add(day);
      }
      day = day.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<void> _loadSpecialties() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getSpecialties();
      if (mounted) setState(() => _specialties = data);
    } catch (_) {
      // Use mock
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadProcedures(int specialtyId) async {
    setState(() {
      _loading = true;
      _procedures = [];
    });
    try {
      final data = await _api.getProcedures(specialtyId);
      if (mounted) setState(() => _procedures = data);
    } catch (_) {
      // filter mock
      if (mounted) setState(() => _procedures = mockProcedures);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSlots() async {
    if (_procedure == null || _date == null) return;
    setState(() {
      _loading = true;
      _slots = [];
    });
    final dateStr =
        '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
    try {
      final data = await _api.getAvailableSlots(_procedure!.id, dateStr);
      if (mounted) setState(() => _slots = data);
    } catch (_) {
      // Mock slots
      if (mounted) {
        setState(() => _slots = [
              const TimeSlot(time: '08:00', available: 5, maxCapacity: 30),
              const TimeSlot(time: '08:30', available: 12, maxCapacity: 30),
              const TimeSlot(time: '09:00', available: 0, maxCapacity: 30),
              const TimeSlot(time: '09:30', available: 8, maxCapacity: 30),
              const TimeSlot(time: '10:00', available: 15, maxCapacity: 30),
              const TimeSlot(time: '10:30', available: 3, maxCapacity: 30),
              const TimeSlot(time: '13:30', available: 20, maxCapacity: 30),
              const TimeSlot(time: '14:00', available: 7, maxCapacity: 30),
              const TimeSlot(time: '14:30', available: 2, maxCapacity: 30),
              const TimeSlot(time: '15:00', available: 0, maxCapacity: 30),
            ]);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmBooking() async {
    final state = context.read<AppState>();
    setState(() => _booking = true);
    try {
      final dateStr =
          '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
      final apt = await _api.createAppointment(
        procedureId: _procedure!.id,
        appointmentDate: dateStr,
        appointmentTime: _time!,
        citizenName: state.studentName,
        citizenId: state.studentId,
        phoneNumber: '0901234567',
      );
      state.addAppointment(apt);
      if (mounted)
        setState(() {
          _booking = false;
          _booked = apt;
          _step = 5;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _booking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _step = 1;
      _specialty = null;
      _procedure = null;
      _date = null;
      _time = null;
      _booked = null;
      _searchTerm = '';
      _procedures = List.of(mockProcedures);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HuitAppBar(
        title: 'Đặt Lịch Hẹn',
        subtitle: 'Phòng Đào Tạo HUIT',
        showBackButton: false,
        actions: [
          if (_step > 1 && _step < 5)
            TextButton(
              onPressed: _reset,
              child: const Text('Làm lại',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_step < 5) _StepIndicator(step: _step),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildSpecialtyStep();
      case 2:
        return _buildProcedureStep();
      case 3:
        return _buildDateTimeStep();
      case 4:
        return _buildConfirmStep();
      case 5:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Specialty ──────────────────────────────────
  Widget _buildSpecialtyStep() {
    return Column(
      key: const ValueKey(1),
      children: [
        _SearchBar(
          hint: 'Tìm loại thủ tục...',
          value: _searchTerm,
          onChanged: (v) => setState(() => _searchTerm = v),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: _filteredSpecialties.length,
                  itemBuilder: (_, i) {
                    final s = _filteredSpecialties[i];
                    return _SpecialtyCard(
                      specialty: s,
                      isSelected: _specialty?.id == s.id,
                      onTap: () {
                        setState(() => _specialty = s);
                        _loadProcedures(s.id);
                        setState(() => _step = 2);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Specialty> get _filteredSpecialties => _specialties
      .where((s) =>
          s.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          s.description.toLowerCase().contains(_searchTerm.toLowerCase()))
      .toList();

  // ── Step 2: Procedure ──────────────────────────────────
  Widget _buildProcedureStep() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackHeader(
          label: _specialty?.name ?? '',
          onBack: () => setState(() => _step = 1),
        ),
        _SearchBar(
          hint: 'Tìm thủ tục...',
          value: _searchTerm,
          onChanged: (v) => setState(() => _searchTerm = v),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: _filteredProcedures.length,
                  itemBuilder: (_, i) {
                    final p = _filteredProcedures[i];
                    return _ProcedureCard(
                      procedure: p,
                      isSelected: _procedure?.id == p.id,
                      onTap: () {
                        setState(() {
                          _procedure = p;
                          _step = 3;
                        });
                        _loadSlots();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Procedure> get _filteredProcedures => _procedures
      .where((p) =>
          p.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchTerm.toLowerCase()))
      .toList();

  // ── Step 3: Date & Time ────────────────────────────────
  Widget _buildDateTimeStep() {
    return SingleChildScrollView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            label: _procedure?.name ?? '',
            onBack: () => setState(() => _step = 2),
          ),
          const SizedBox(height: 12),

          // Date selector
          Text('Chọn ngày', style: AppTextStyles.h4),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _availableDates.length,
              itemBuilder: (_, i) {
                final d = _availableDates[i];
                final isSelected = _date != null &&
                    _date!.day == d.day &&
                    _date!.month == d.month;
                const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6'];
                final wd = weekdays[d.weekday - 1];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _date = d;
                      _time = null;
                    });
                    _loadSlots();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 0.8,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          wd,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textHeading,
                          ),
                        ),
                        Text(
                          'T${d.month}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          Text('Chọn giờ', style: AppTextStyles.h4),
          const SizedBox(height: 4),
          Text(
            'Màu xám = hết chỗ',
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 10),

          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ))
          else if (_slots.isEmpty && _date != null)
            _EmptyState(
              icon: Icons.access_time_outlined,
              label: 'Không có khung giờ trống',
              sub: 'Vui lòng chọn ngày khác',
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _slots.map((slot) {
                final isFull = slot.isFull;
                final isSelected = _time == slot.time;
                return GestureDetector(
                  onTap:
                      isFull ? null : () => setState(() => _time = slot.time),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isFull
                          ? AppColors.border
                          : isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          slot.time,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isFull
                                ? AppColors.textDisabled
                                : isSelected
                                    ? Colors.white
                                    : AppColors.textHeading,
                          ),
                        ),
                        if (!isFull)
                          Text(
                            '${slot.available} chỗ',
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 28),
          HuitButton(
            label: 'Tiếp tục',
            fullWidth: true,
            size: HuitButtonSize.large,
            icon: Icons.arrow_forward_rounded,
            iconRight: true,
            onPressed: _date != null && _time != null
                ? () => setState(() => _step = 4)
                : null,
          ),
        ],
      ),
    );
  }

  // ── Step 4: Confirm ────────────────────────────────────
  Widget _buildConfirmStep() {
    final state = context.read<AppState>();
    return SingleChildScrollView(
      key: const ValueKey(4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            label: 'Xác nhận đặt lịch',
            onBack: () => setState(() => _step = 3),
          ),
          const SizedBox(height: 16),

          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ConfirmRow(
                    icon: Icons.category_outlined,
                    label: 'Loại thủ tục',
                    value: _specialty?.name ?? ''),
                const Divider(height: 20),
                _ConfirmRow(
                    icon: Icons.description_outlined,
                    label: 'Thủ tục',
                    value: _procedure?.name ?? ''),
                const Divider(height: 20),
                _ConfirmRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày hẹn',
                  value: _date != null
                      ? '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}'
                      : '',
                ),
                const Divider(height: 20),
                _ConfirmRow(
                    icon: Icons.access_time_outlined,
                    label: 'Giờ hẹn',
                    value: _time ?? ''),
                const Divider(height: 20),
                _ConfirmRow(
                    icon: Icons.person_outline,
                    label: 'Sinh viên',
                    value: state.studentName),
                const Divider(height: 20),
                _ConfirmRow(
                    icon: Icons.badge_outlined,
                    label: 'MSSV',
                    value: state.studentId),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Required docs
          if (_procedure != null &&
              _procedure!.requiredDocuments.isNotEmpty) ...[
            Text('Giấy tờ cần mang theo', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            ...(_procedure!.requiredDocuments.map((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(doc,
                              style:
                                  AppTextStyles.body.copyWith(fontSize: 13))),
                    ],
                  ),
                ))),
            const SizedBox(height: 20),
          ],

          HuitButton(
            label: 'Xác nhận đặt lịch',
            fullWidth: true,
            size: HuitButtonSize.large,
            isLoading: _booking,
            onPressed: _booking ? null : _confirmBooking,
            icon: Icons.check_rounded,
          ),
          const SizedBox(height: 10),
          HuitButton(
            label: 'Quay lại chỉnh sửa',
            fullWidth: true,
            variant: HuitButtonVariant.outline,
            onPressed: () => setState(() => _step = 3),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Success ────────────────────────────────────
  Widget _buildSuccessStep() {
    return Center(
      key: const ValueKey(5),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Đặt lịch thành công!',
              style: AppTextStyles.h2.copyWith(color: AppColors.success),
            ),
            const SizedBox(height: 8),
            Text(
              'Số thứ tự của bạn',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _booked?.queueDisplay ?? '--',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_booked != null) ...[
              _ResultRow(label: 'Thủ tục', value: _booked!.procedureName),
              _ResultRow(
                label: 'Ngày hẹn',
                value:
                    '${_booked!.appointmentDate} lúc ${_booked!.appointmentTime}',
              ),
              _ResultRow(label: 'Mã lịch hẹn', value: _booked!.code),
            ],
            const SizedBox(height: 28),
            HuitButton(
              label: 'Đặt lịch mới',
              fullWidth: true,
              onPressed: _reset,
              variant: HuitButtonVariant.outline,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const steps = ['Danh mục', 'Thủ tục', 'Ngày & Giờ', 'Xác nhận'];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (i) {
          final active = i + 1 == step;
          final done = i + 1 < step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.success
                              : active
                                  ? AppColors.primary
                                  : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: active || done
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : done
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: done ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.hint,
    required this.value,
    required this.onChanged,
  });
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon:
              const Icon(Icons.search, color: AppColors.primary, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.label, required this.onBack});
  final String label;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.primary, size: 16),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: AppTextStyles.h4,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _SpecialtyCard extends StatelessWidget {
  const _SpecialtyCard({
    required this.specialty,
    required this.isSelected,
    required this.onTap,
  });
  final Specialty specialty;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_outlined,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(specialty.name,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(specialty.description,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcedureCard extends StatelessWidget {
  const _ProcedureCard({
    required this.procedure,
    required this.isSelected,
    required this.onTap,
  });
  final Procedure procedure;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    procedure.name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    procedure.code,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary, fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(procedure.description,
                style: AppTextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${procedure.processingDays} ngày làm việc',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.description_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${procedure.requiredDocuments.length} giấy tờ',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
              const SizedBox(height: 1),
              Text(value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.label,
    required this.sub,
  });
  final IconData icon;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, color: AppColors.border, size: 48),
          const SizedBox(height: 12),
          Text(label,
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(sub, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
