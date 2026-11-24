
import 'package:flutter/material.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/debouncer.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/features/employees/presentation/employee_form.dart';
import 'package:hrms/features/special_days/presentation/special_days_controller.dart';
import 'package:hrms/features/special_days/presentation/special_days_page.dart';

import 'employees_controller.dart';

class EmployeesFeaturePage extends StatefulWidget {
  const EmployeesFeaturePage({super.key});

  @override
  State<EmployeesFeaturePage> createState() =>
      _EmployeesFeaturePageState();
}

class _EmployeesFeaturePageState extends State<EmployeesFeaturePage> {
  late final EmployeesController _controller;
  late final SpecialDaysController _specialDaysController;

  final TextEditingController _searchController =
  TextEditingController();
  final Debouncer _debouncer = Debouncer();

  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();

    _controller = EmployeesController();
    _specialDaysController = SpecialDaysController();

    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    _specialDaysController.dispose();
    _debouncer.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // LOAD EMPLOYEES
  // ------------------------------------------------------------

  Future<void> _load() async {
    try {
      debugPrint('LOADING EMPLOYEES');

      await _controller.loadEmployees();

      debugPrint('EMPLOYEES LOADED: ${_controller.rows.length}');

      if (mounted) {
        setState(() {});
      }
    } catch (e, st) {
      debugPrint('LOAD EMPLOYEES ERROR: $e\n$st');

      if (mounted) {
        toast(context, 'Unable to load employees: $e');
      }
    }
  }

  // ------------------------------------------------------------
  // ADD / EDIT EMPLOYEE
  // ------------------------------------------------------------

  Future<void> _edit([EmployeeEntity? employee]) async {
    try {
      debugPrint('EDIT EMPLOYEE ID: ${employee?.id}');

      final result = await showEmployeeForm(
        context,
        existing: employee,
      );

      if (!mounted || result == null) return;

      await _load();

      if (!mounted) return;

      toast(
        context,
        employee == null
            ? 'Employee added successfully'
            : 'Employee updated successfully',
      );
    } catch (e, st) {
      debugPrint('EDIT EMPLOYEE ERROR: $e');
      debugPrintStack(stackTrace: st);

      if (mounted) {
        toast(context, 'Edit failed: $e');
      }
    }
  }
  // ------------------------------------------------------------
  // ADD SPECIAL DAY
  // ------------------------------------------------------------

  Future<void> _addSpecialDay(EmployeeEntity employee) async {
    debugPrint('ADD SPECIAL DAY: ${employee.id}');

    try {
      final result = await showSpecialDayForm(
        context,
        _specialDaysController,
        empId: employee.id,
      );

      if (!mounted || result != true) return;

      toast(context, 'Special day added');
    } catch (e, st) {
      debugPrint('SPECIAL DAY ERROR: $e\n$st');

      if (mounted) {
        toast(context, 'Error adding special day: $e');
      }
    }
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  Widget _buildSearchField(ColorScheme cs) {
    return SizedBox(
      width: 260,
      height: 42,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _debouncer.run(() {
            _controller.setSearchQuery(value);
          });
        },
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search employees...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
          ),
          filled: true,
          fillColor:
          cs.surfaceContainerHighest.withValues(alpha: 0.35),
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(
              color: cs.primary,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ADD EMPLOYEE BUTTON
  // ------------------------------------------------------------

  Widget _buildAddButton() {
    return SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: () => _edit(),
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          size: 16,
        ),
        label: const Text('Add Employee'),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // STATUS FILTER
  // ------------------------------------------------------------

  Widget _buildStatusFilterBar(ColorScheme cs) {
    const filters = ['All', 'Active', 'Inactive'];

    return Row(
      children: [
        for (final filter in filters) ...[
          ChoiceChip(
            label: Text(filter),
            selected: _statusFilter == filter,
            onSelected: (selected) {
              if (!selected) return;

              setState(() {
                _statusFilter = filter;
              });
            },
            selectedColor: cs.primaryContainer,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _statusFilter == filter
                  ? cs.onPrimaryContainer
                  : cs.onSurface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: _statusFilter == filter
                    ? cs.primary
                    : Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // EMPLOYEE CARD
  // ------------------------------------------------------------

  Widget _buildEmployeeCard(
      EmployeeEntity emp,
      ColorScheme cs,
      ) {
    final isActive =
        emp.s('status').trim().toLowerCase() == 'active';

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _edit(emp),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  emp.name.isEmpty
                      ? '?'
                      : emp.name[0].toUpperCase(),
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            emp.name.isEmpty
                                ? 'Unnamed'
                                : emp.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(
                          isActive ? 'Active' : 'Inactive',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${emp.code}  •  ${emp.department}  •  ${emp.designation}  •  Branch: ${emp.s('branch').isEmpty ? '—' : emp.s('branch')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    tooltip: 'Edit Employee',
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                    ),
                    onPressed: () => _edit(emp),
                  ),
                  if (Session.isHr)
                    IconButton(
                      tooltip: 'Special Day',
                      icon: const Icon(
                        Icons.cake_outlined,
                        size: 18,
                      ),
                      onPressed: () => _addSpecialDay(emp),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPLOYEE CONTENT
  // ------------------------------------------------------------

  Widget _buildContent(ColorScheme cs) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading &&
            _controller.rows.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final employees = _controller.rows.where((emp) {
          final status =
          emp.s('status').trim().toLowerCase();

          if (_statusFilter == 'Active') {
            return status == 'active';
          }

          if (_statusFilter == 'Inactive') {
            return status != 'active';
          }

          return true;
        }).toList();

        if (employees.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 48,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No employees found',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if(Session.canEditEmployees)
                FilledButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(
                    Icons.person_add_alt_1,
                  ),
                  label: const Text('Add Employee'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: employees.length,
          separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildEmployeeCard(
              employees[index],
              cs,
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // PAGE BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PageBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(
            'Employees',
            actions: [
              _buildSearchField(cs),
              const SizedBox(width: 10),
              _buildAddButton(),
            ],
          ),
          const SizedBox(height: 14),
          _buildStatusFilterBar(cs),
          const SizedBox(height: 14),
          Expanded(
            child: _buildContent(cs),
          ),
        ],
      ),
    );
  }
}
