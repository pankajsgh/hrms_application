
import 'package:flutter/material.dart';

import 'package:hrms/features/employees/presentation/employee_form.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import '../../special_days/presentation/special_days_page.dart';
import 'employees_controller.dart';

class EmployeesFeaturePage extends StatefulWidget {
  const EmployeesFeaturePage({super.key});

  @override
  State<EmployeesFeaturePage> createState() =>
      _EmployeesFeaturePageState();
}

class _EmployeesFeaturePageState extends State<EmployeesFeaturePage> {
  late final EmployeesController _controller;

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = EmployeesController();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD EMPLOYEES
  // ---------------------------------------------------------------------------

  Future<void> _loadEmployees() async {
    try {
      await _controller.loadEmployees();
    } catch (e, stackTrace) {
      debugPrint('LOAD EMPLOYEES ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Unable to load employees: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // ADD / EDIT EMPLOYEE
  // ---------------------------------------------------------------------------

  Future<void> _edit([Rec? employee]) async {
    try {
      final id = await showEmployeeForm(
        context,
        existing: employee,
      );

      if (!mounted || id == null) return;

      await _loadEmployees();

      if (!mounted) return;

      toast(
        context,
        employee == null
            ? 'Employee added successfully'
            : 'Employee updated successfully',
      );
    } catch (e, stackTrace) {
      debugPrint('EMPLOYEE SAVE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Unable to save employee: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  void _onSearch(String value) {
    _controller.setSearchQuery(value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    _controller.setSearchQuery('');
  }

  Widget _buildSearchField({bool expanded = false}) {
    final theme = Theme.of(context);

    return SizedBox(
      width: expanded ? double.infinity : 260,
      height: 42,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search name, code or department...',
          hintStyle: TextStyle(
            fontSize: 11.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 42,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
            tooltip: 'Clear search',
            onPressed: _clearSearch,
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
            ),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.35),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.45),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ADD BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildAddButton({bool compact = false}) {
    return SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: () => _edit(),
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          size: 16,
        ),
        label: Text(
          compact ? 'Add' : 'Add Employee',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY CARD
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    final theme = Theme.of(context);

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  count.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<Rec> employees) {
    final active = employees
        .where((e) => e.s('status').toLowerCase() == 'active')
        .length;

    final inactive = employees.length - active;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 570;

        final cards = [
          _buildSummaryCard(
            title: 'Showing Employees',
            count: employees.length,
            icon: Icons.groups_rounded,
            color: Colors.blue,
            background: Colors.blue.withValues(alpha: 0.12),
          ),
          _buildSummaryCard(
            title: 'Active',
            count: active,
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            background: Colors.green.withValues(alpha: 0.12),
          ),
          _buildSummaryCard(
            title: 'Inactive',
            count: inactive,
            icon: Icons.pause_circle_outline_rounded,
            color: Colors.orange,
            background: Colors.orange.withValues(alpha: 0.12),
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1)
                const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // EMPLOYEE AVATAR
  // ---------------------------------------------------------------------------

  Widget _buildEmployeeAvatar(Rec employee) {
    final theme = Theme.of(context);
    final name = employee.s('name').trim();

    final initials = name.isEmpty
        ? '?'
        : name
        .split(RegExp(r'\s+'))
        .take(2)
        .map(
          (part) => part.isEmpty
          ? ''
          : part[0].toUpperCase(),
    )
        .join();

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPLOYEE INFORMATION
  // ---------------------------------------------------------------------------

  Widget _buildEmployeeInfo(Rec employee) {
    final theme = Theme.of(context);

    final name = employee.s('name');
    final email = employee.s('email');
    final phone = employee.s('phone');

    return Row(
      children: [
        _buildEmployeeAvatar(employee),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Unnamed employee' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                email.isNotEmpty ? email : phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EMPLOYEE STATUS
  // ---------------------------------------------------------------------------

  Widget _buildStatus(String value) {
    final active = value.toLowerCase() == 'active';
    final color = active ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value.isEmpty ? 'Unknown' : value,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPLOYEE ACTIONS
  // ---------------------------------------------------------------------------

  Widget _buildEmployeeActions(Rec employee) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Edit employee',
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer
                .withValues(alpha: 0.5),
          ),
          icon: const Icon(
            Icons.edit_outlined,
            size: 17,
          ),
          onPressed: () => _edit(employee),
        ),
        if (Session.isHr) ...[
          const SizedBox(width: 5),
          IconButton(
            tooltip: 'Add special day',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
              backgroundColor: Colors.orange.withValues(alpha: 0.10),
            ),
            icon: const Icon(
              Icons.cake_outlined,
              size: 17,
            ),
            onPressed: () => _addSpecialDay(employee),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ADD SPECIAL DAY
  // ---------------------------------------------------------------------------

  Future<void> _addSpecialDay(Rec employee) async {
    try {
      final ok = await showSpecialDayForm(
        context,
        empId: employee.i('id'),
      );

      if (!mounted) return;

      if (ok) {
        toast(context, 'Special day added');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to add special day: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final hasSearch = _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                size: 38,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasSearch
                  ? 'No employees found'
                  : 'No employees yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasSearch
                  ? 'Try another employee name, code or department.'
                  : 'Add your first employee to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 18),
              _buildAddButton(),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPLOYEE TABLE
  // ---------------------------------------------------------------------------

  Widget _buildEmployeeTable(List<Rec> employees) {
    final theme = Theme.of(context);

    return TableCard(
      columns: const [
        DataColumn(label: Text('Employee')),
        DataColumn(label: Text('Code')),
        DataColumn(label: Text('Department')),
        DataColumn(label: Text('Designation')),
        DataColumn(label: Text('Branch')),
        DataColumn(label: Text('Manager')),
        DataColumn(label: Text('Joined')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: [
        for (int index = 0; index < employees.length; index++)
          DataRow(
            color: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.hovered)) {
                return theme.colorScheme.primary
                    .withValues(alpha: 0.09);
              }

              return index.isEven
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.30);
            }),
            cells: [
              DataCell(
                _buildEmployeeInfo(employees[index]),
              ),
              DataCell(
                Text(
                  employees[index].s('code'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              DataCell(
                Text(
                  employees[index].s('department'),
                  style: const TextStyle(fontSize: 10.5),
                ),
              ),
              DataCell(
                Text(
                  employees[index].s('designation'),
                  style: const TextStyle(fontSize: 10.5),
                ),
              ),
              DataCell(
                Text(
                  employees[index].s('branch'),
                  style: const TextStyle(fontSize: 10.5),
                ),
              ),
              DataCell(
                Text(
                  employees[index].s('manager_name').isEmpty
                      ? '—'
                      : employees[index].s('manager_name'),
                  style: const TextStyle(fontSize: 10.5),
                ),
              ),
              DataCell(
                Text(
                  fmtDate(employees[index]['join_date']),
                  style: const TextStyle(fontSize: 10.5),
                ),
              ),
              DataCell(
                _buildStatus(employees[index].s('status')),
              ),
              DataCell(
                _buildEmployeeActions(employees[index]),
              ),
            ],
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildContent() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading && _controller.rows.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final employees = _controller.rows;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummary(employees),
            const SizedBox(height: 16),
            Expanded(
              child: employees.isEmpty
                  ? _buildEmptyState()
                  : _buildEmployeeTable(employees),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final narrow = width < 800;

    return PageBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (narrow) ...[
            Header(
              'Employees',
              actions: [
                _buildAddButton(compact: true),
              ],
            ),
            const SizedBox(height: 12),
            _buildSearchField(expanded: true),
          ] else
            Header(
              'Employees',
              actions: [
                _buildSearchField(),
                _buildAddButton(),
              ],
            ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}
