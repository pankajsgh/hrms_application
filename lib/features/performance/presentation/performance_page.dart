import 'package:flutter/material.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/comman_widget/customer_dropdown.dart';
import 'package:hrms/domain/entities/performance_entity.dart';
import 'package:hrms/features/employees/data/employees_repository.dart';

import 'performance_controller.dart';

class PerformanceFeaturePage extends StatefulWidget {
  const PerformanceFeaturePage({super.key});

  @override
  State<PerformanceFeaturePage> createState() =>
      _PerformanceFeaturePageState();
}

class _PerformanceFeaturePageState extends State<PerformanceFeaturePage>
    with SingleTickerProviderStateMixin {
  late final PerformanceController controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = PerformanceController();
    controller.loadPerformance();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PageBox(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Header(
                'Performance Management',
                actions: [
                  if (controller.isLoading)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: cs.onPrimary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'Goals'),
                    Tab(text: 'Performance Reviews'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _GoalsTab(controller: controller),
                    _ReviewsTab(controller: controller),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// GOALS TAB
// ============================================================

class _GoalsTab extends StatelessWidget {
  final PerformanceController controller;

  const _GoalsTab({required this.controller});

  Future<void> _edit(
      BuildContext context, [
        GoalEntity? goal,
      ]) async {
    final employees = await EmployeesRepository().scopeEmployees();
    if (!context.mounted) return;

    if (employees.isEmpty) {
      toast(context, 'No employees found');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: goal?.title ?? '');
    final descriptionController =
    TextEditingController(text: goal?.description ?? '');
    final progressController =
    TextEditingController(text: '${goal?.progress ?? 0}');

    int? employeeId = goal?.employeeId ?? Session.empId;
    String dueDate = goal?.dueDate ?? '';
    String status = goal?.status ?? 'Pending';

    if (!employees.any((e) => e.id == employeeId)) {
      employeeId = employees.first.id;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(goal == null ? 'Add Goal' : 'Edit Goal'),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomDropdown<int>(
                          label: 'Employee',
                          value: employeeId,
                          items: employees
                              .map((e) => DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(e.name),
                          ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => employeeId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text('Goal Title',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Enter goal title',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter goal title'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        const Text('Description',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Details / milestone description',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Due Date',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 7),
                        InkWell(
                          onTap: () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(dueDate) ??
                                  DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );

                            if (selected != null) {
                              setDialogState(() {
                                dueDate = ymd(selected);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dueDate.isEmpty
                                      ? 'Select due date'
                                      : dueDate,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: dueDate.isEmpty
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                                const Icon(Icons.calendar_month_outlined,
                                    size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Progress (%)',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: progressController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0 - 100',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: (value) {
                            final p = int.tryParse(value ?? '');
                            if (p == null || p < 0 || p > 100) {
                              return 'Enter 0 to 100';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        CustomDropdown<String>(
                          label: 'Status',
                          value: status,
                          items: const [
                            DropdownMenuItem(
                                value: 'Pending', child: Text('Pending')),
                            DropdownMenuItem(
                                value: 'In Progress',
                                child: Text('In Progress')),
                            DropdownMenuItem(
                                value: 'Completed', child: Text('Completed')),
                            DropdownMenuItem(
                                value: 'On Hold', child: Text('On Hold')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => status = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && employeeId != null) {
      final data = GoalEntity(
        employeeId: employeeId!,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        dueDate: dueDate,
        progress: (int.tryParse(progressController.text) ?? 0)
            .clamp(0, 100)
            .toInt(),
        status: status,
      );

      await controller.saveGoal(data, id: goal?.id);
    }

    titleController.dispose();
    descriptionController.dispose();
    progressController.dispose();
  }

  Future<void> _delete(BuildContext context, GoalEntity goal) async {
    final ok = await confirm(
        context, 'Delete Goal', 'Are you sure you want to delete "${goal.title}"?');
    if (ok && goal.id != null) {
      await controller.deleteGoal(goal.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = controller.goals;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Goals (${goals.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Goal'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: goals.isEmpty
              ? const Center(child: Text('No goals found'))
              : ListView.separated(
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          StatusChip(goal.status),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            onPressed: () => _edit(context, goal),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline,
                                size: 17, color: Colors.red),
                            onPressed: () => _delete(context, goal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                          Text(
                            goal.empName ?? 'Employee',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today_outlined,
                              size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            goal.dueDate.isEmpty
                                ? 'No due date'
                                : 'Due: ${goal.dueDate}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (goal.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          goal.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: goal.progress.clamp(0, 100) / 100,
                                minHeight: 6,
                                backgroundColor: cs.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${goal.progress}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// REVIEWS TAB
// ============================================================

class _ReviewsTab extends StatelessWidget {
  final PerformanceController controller;

  const _ReviewsTab({required this.controller});

  Future<void> _add(BuildContext context) async {
    final employees = await EmployeesRepository().scopeEmployees();
    if (!context.mounted) return;

    final availableEmployees = employees
        .where((e) => e.id != Session.empId)
        .toList();

    if (availableEmployees.isEmpty) {
      toast(context, 'No employees available for review');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final periodController = TextEditingController();
    final strengthsController = TextEditingController();
    final improvementsController = TextEditingController();
    final commentsController = TextEditingController();

    int? employeeId = availableEmployees.first.id;
    int rating = 5;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Add Performance Review'),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomDropdown<int>(
                          label: 'Employee',
                          value: employeeId,
                          items: availableEmployees
                              .map((e) => DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(e.name),
                          ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => employeeId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text('Review Period',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: periodController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Q3 2026 / November 2026',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter review period'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        CustomDropdown<int>(
                          label: 'Rating',
                          value: rating,
                          items: const [
                            DropdownMenuItem(
                                value: 5, child: Text('5 - Outstanding')),
                            DropdownMenuItem(
                                value: 4,
                                child: Text('4 - Exceeds Expectations')),
                            DropdownMenuItem(
                                value: 3, child: Text('3 - Meets Expectations')),
                            DropdownMenuItem(
                                value: 2,
                                child: Text('2 - Needs Improvement')),
                            DropdownMenuItem(
                                value: 1, child: Text('1 - Unsatisfactory')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => rating = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text('Strengths',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: strengthsController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Employee strengths...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Areas for Improvement',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: improvementsController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Growth opportunities...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Comments',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: commentsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Detailed review comments...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter comments'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text('Save Review'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && employeeId != null) {
      final data = ReviewEntity(
        employeeId: employeeId!,
        reviewerId: Session.empId ?? 0,
        period: periodController.text.trim(),
        rating: rating,
        strengths: strengthsController.text.trim(),
        improvements: improvementsController.text.trim(),
        comments: commentsController.text.trim(),
        createdOn: ymd(DateTime.now()),
      );

      await controller.saveReview(data);
    }

    periodController.dispose();
    strengthsController.dispose();
    improvementsController.dispose();
    commentsController.dispose();
  }

  Future<void> _view(BuildContext context, ReviewEntity review) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Review: ${review.empName ?? 'Employee'}'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail('Review Period', review.period),
                  _detail('Rating', '${review.rating} / 5 Stars'),
                  _detail('Strengths', review.strengths),
                  _detail('Areas for Improvement', review.improvements),
                  _detail('Comments', review.comments),
                  _detail('Reviewer', review.reviewerName ?? 'Manager'),
                  _detail('Date', review.createdOn),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, ReviewEntity review) async {
    final ok = await confirm(context, 'Delete Review',
        'Are you sure you want to delete this performance review?');
    if (ok && review.id != null) {
      await controller.deleteReview(review.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = controller.reviews;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance Reviews (${reviews.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            FilledButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Review'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: reviews.isEmpty
              ? const Center(child: Text('No reviews found'))
              : ListView.separated(
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _view(context, review),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${review.rating}★',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.empName ?? 'Employee',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Period: ${review.period}  •  Reviewer: ${review.reviewerName ?? 'Manager'}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'View details',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 17),
                              onPressed: () => _view(context, review),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline,
                                  size: 17, color: Colors.red),
                              onPressed: () => _delete(context, review),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
