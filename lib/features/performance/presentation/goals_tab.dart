
import 'package:flutter/material.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/comman_widget/customer_dropdown.dart';
import 'package:hrms/domain/entities/performance_entity.dart';
import 'package:hrms/features/employees/data/employees_repository.dart';

import 'performance_controller.dart';

// ============================================================
// GOALS TAB
// ============================================================

class GoalsTab extends StatelessWidget {
  final PerformanceController controller;

  const GoalsTab({
    super.key,
    required this.controller,
  });

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

    final titleController = TextEditingController(
      text: goal?.title ?? '',
    );

    final descriptionController = TextEditingController(
      text: goal?.description ?? '',
    );

    final progressController = TextEditingController(
      text: '${goal?.progress ?? 0}',
    );

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
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                goal == null ? 'Add Goal' : 'Edit Goal',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 420,
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
                              .map(
                                (e) => DropdownMenuItem<int>(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                employeeId = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 10),

                        _GoalField(
                          label: 'Goal Title',
                          child: TextFormField(
                            controller: titleController,
                            decoration: _inputDecoration(
                              'Enter goal title',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter goal title';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        _GoalField(
                          label: 'Description',
                          child: TextFormField(
                            controller: descriptionController,
                            maxLines: 2,
                            decoration: _inputDecoration(
                              'Details / milestone description',
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _GoalField(
                          label: 'Due Date',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate:
                                DateTime.tryParse(dueDate) ??
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
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dueDate.isEmpty
                                          ? 'Select due date'
                                          : dueDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: dueDate.isEmpty
                                            ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _GoalField(
                          label: 'Progress (%)',
                          child: TextFormField(
                            controller: progressController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('0 - 100'),
                            validator: (value) {
                              final progress = int.tryParse(value ?? '');

                              if (progress == null ||
                                  progress < 0 ||
                                  progress > 100) {
                                return 'Enter a value between 0 and 100';
                              }

                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        CustomDropdown<String>(
                          label: 'Status',
                          value: status,
                          items: const [
                            DropdownMenuItem(
                              value: 'Pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'In Progress',
                              child: Text('In Progress'),
                            ),
                            DropdownMenuItem(
                              value: 'Completed',
                              child: Text('Completed'),
                            ),
                            DropdownMenuItem(
                              value: 'On Hold',
                              child: Text('On Hold'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                status = value;
                              });
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
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
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

      await controller.saveGoal(
        data,
        id: goal?.id,
      );
    }

    titleController.dispose();
    descriptionController.dispose();
    progressController.dispose();
  }

  Future<void> _delete(
      BuildContext context,
      GoalEntity goal,
      ) async {
    final ok = await confirm(
      context,
      'Delete Goal',
      'Are you sure you want to delete "${goal.title}"?',
    );

    if (ok && goal.id != null) {
      await controller.deleteGoal(goal.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = controller.goals;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text(
                'Goals (${goals.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add, size: 15),
              label: const Text(
                'Add Goal',
                style: TextStyle(fontSize: 12),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                minimumSize: const Size(0, 34),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Goal list
        Expanded(
          child: goals.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 35,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No goals found',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: goals.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 7),
            itemBuilder: (context, index) {
              final goal = goals[index];

              return GoalCard(
                goal: goal,
                onEdit: () => _edit(context, goal),
                onDelete: () => _delete(context, goal),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SEPARATE REUSABLE GOAL CARD
// ============================================================

class GoalCard extends StatelessWidget {
  final GoalEntity goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = goal.progress.clamp(0, 100);
    final progressValue = progress / 100;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and actions
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              StatusChip(goal.status),

              PopupMenuButton<String>(
                tooltip: 'More options',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 35,
                  minHeight: 35,
                ),
                iconSize: 18,
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Employee and due date
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _GoalInfo(
                icon: Icons.person_outline,
                text: goal.empName ?? 'Employee',
                color: cs.primary,
              ),
              _GoalInfo(
                icon: Icons.calendar_today_outlined,
                text: goal.dueDate.isEmpty
                    ? 'No due date'
                    : 'Due: ${goal.dueDate}',
                color: cs.onSurfaceVariant,
              ),
            ],
          ),

          // Description
          if (goal.description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              goal.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 9),

          // Progress
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progressValue.toDouble(),
                    minHeight: 5,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                '$progress%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GOAL INFO
// ============================================================

class _GoalInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _GoalInfo({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FORM FIELD HELPER
// ============================================================

class _GoalField extends StatelessWidget {
  final String label;
  final Widget child;

  const _GoalField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

// ============================================================
// INPUT DECORATION
// ============================================================

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12),
    filled: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 11,
      vertical: 11,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}
