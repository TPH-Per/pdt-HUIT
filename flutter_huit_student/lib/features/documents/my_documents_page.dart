import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/app_state.dart';
import '../../data/models.dart';
import '../../shared/widgets/huit_app_bar.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/huit_button.dart';

class MyDocumentsPage extends StatefulWidget {
  const MyDocumentsPage({super.key});

  @override
  State<MyDocumentsPage> createState() => _MyDocumentsPageState();
}

class _MyDocumentsPageState extends State<MyDocumentsPage> {
  String _activeCategory = 'Tất cả';

  final _categories = ['Tất cả', 'Academic', 'Personal', 'Forms'];
  final _categoryLabels = {
    'Tất cả': 'Tất cả',
    'Academic': 'Học tập',
    'Personal': 'Cá nhân',
    'Forms': 'Biểu mẫu',
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtered = _activeCategory == 'Tất cả'
        ? state.documents
        : state.documents.where((d) => d.category == _activeCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HuitAppBar(
        title: 'Hồ Sơ Số',
        subtitle: 'Tài liệu học tập của tôi',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined,
                color: Colors.white, size: 22),
            tooltip: 'Tải lên',
            onPressed: () => _showUploadSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category Filter ───────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isActive = cat == _activeCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          _categoryLabels[cat]!,
                          style: AppTextStyles.label.copyWith(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Documents List ────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open_outlined,
                            color: AppColors.border, size: 56),
                        const SizedBox(height: 12),
                        Text('Không có tài liệu',
                            style: AppTextStyles.h4.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) =>
                        _DocumentCard(document: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _UploadSheet(),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});
  final AppDocument document;

  static const _typeColors = {
    'PDF': Color(0xFFE53935),
    'IMG': Color(0xFF1E88E5),
    'DOC': Color(0xFF1976D2),
    'XLS': Color(0xFF388E3C),
  };

  @override
  Widget build(BuildContext context) {
    final typeColor =
        _typeColors[document.type] ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // File type badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                document.type,
                style: TextStyle(
                                    fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: typeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${document.size} • ${document.date}',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 5),
                StatusBadge(status: document.status),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondary, size: 20),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('Xem')),
              const PopupMenuItem(value: 'download', child: Text('Tải về')),
              const PopupMenuItem(value: 'delete', child: Text('Xoá')),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadSheet extends StatefulWidget {
  const _UploadSheet();

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Tải lên tài liệu', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Chọn loại tài liệu và tệp.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Category
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Loại tài liệu',
              prefixIcon: Icon(Icons.folder_outlined, color: AppColors.primary),
            ),
            items: ['Học tập', 'Cá nhân', 'Biểu mẫu'].map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 16),

          // File picker placeholder
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: AppColors.primary, size: 36),
                  const SizedBox(height: 8),
                  Text('Nhấn để chọn tệp',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.primary)),
                  Text('PDF, Word, Image (tối đa 10MB)',
                      style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          HuitButton(
            label: 'Tải lên',
            fullWidth: true,
            size: HuitButtonSize.large,
            icon: Icons.upload_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
