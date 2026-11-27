
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms/comman_widget/customer_dropdown.dart';
import 'package:hrms/data/global_data.dart';
import 'package:hrms/features/employees/data/employees_repository.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/domain/entities/employee_entity.dart';

Future<int?> showEmployeeForm(
    BuildContext context, {
      EmployeeEntity? existing,
    }) async {

  final isNew = existing == null;

  final initialCode = isNew ? await EmployeesRepository().nextCode() : existing.s('code');

  if (!context.mounted) return null;

  final codeCtrl = TextEditingController(text: initialCode);
  final nameCtrl = TextEditingController(
    text: existing?.s('name') ?? '',
  );
  final emailCtrl = TextEditingController(
    text: existing?.s('email') ?? '',
  );
  final phoneCtrl = TextEditingController(
    text: existing?.s('phone') ?? '',
  );
  final deptCtrl = TextEditingController(
    text: existing?.s('department') ?? '',
  );
  final desigCtrl = TextEditingController(
    text: existing?.s('designation') ?? '',
  );
  final addressCtrl = TextEditingController(
    text: existing?.s('address') ?? '',
  );
  final bankCtrl = TextEditingController(
    text: existing?.s('bank_account') ?? '',
  );

  final basicCtrl = TextEditingController(
    text: nf(existing?.d('basic') ?? 0),
  );
  final hraCtrl = TextEditingController(
    text: nf(existing?.d('hra') ?? 0),
  );
  final allowancesCtrl = TextEditingController(
    text: nf(existing?.d('allowances') ?? 0),
  );
  final pfCtrl = TextEditingController(
    text: nf(existing?.d('pf_percent') ?? 12),
  );
  final deductCtrl = TextEditingController(
    text: nf(existing?.d('other_deduction') ?? 0),
  );

  final controllers = [
    codeCtrl,
    nameCtrl,
    emailCtrl,
    phoneCtrl,
    deptCtrl,
    desigCtrl,
    addressCtrl,
    bankCtrl,
    basicCtrl,
    hraCtrl,
    allowancesCtrl,
    pfCtrl,
    deductCtrl,
  ];

  final formKey = GlobalKey<FormState>();

  final currentStatus = existing?.s('status') ?? '';
  String status = currentStatus == 'Inactive' ? 'Inactive' : 'Active';

  // Keep a previously saved custom branch selectable during editing.
  final branchOptions = List<String>.from(kBranchOffices);
  final currentBranch = existing?.s('branch').trim() ?? '';

  if (currentBranch.isNotEmpty &&
      !branchOptions.contains(currentBranch)) {
    branchOptions.insert(0, currentBranch);
  }

  if (branchOptions.isEmpty) {
    throw StateError(
      'kBranchOffices must contain at least one branch.',
    );
  }

  String branch = currentBranch.isNotEmpty
      ? currentBranch
      : branchOptions.first;

  int? managerId = existing?.i('manager_id');

  String joinDate = existing?.s('join_date').isEmpty ?? true
      ? ymd(DateTime.now())
      : existing!.s('join_date');

  // Preserve an existing custom department.
  final currentDepartment = deptCtrl.text.trim();

  if (currentDepartment.isNotEmpty &&
      !departmentOptions.contains(currentDepartment)) {
    departmentOptions.insert(0, currentDepartment);
  }

  List<EmployeeEntity> managerOptions;

  try {
    final emps = await EmployeesRepository().fetchEmployees(activeOnly: true);

    managerOptions = emps
        .where((e) => e.i('id') != existing?.i('id'))
        .toList();
  } catch (e) {
    // Do not leave controllers undisposed if manager loading fails.
    for (final controller in controllers) {
      controller.dispose();
    }
    rethrow;
  }

  // Keep saving outside StatefulBuilder so it survives rebuilds.
  bool saving = false;

  double amount(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  try {
    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _EmployeeFormControllerOwner(
          controllers: controllers,
          child: StatefulBuilder(
            builder: (context, setState) {
              final basic = amount(basicCtrl);
              final hra = amount(hraCtrl);
              final allowances = amount(allowancesCtrl);
              final pfPercent = amount(pfCtrl);
              final deductions = amount(deductCtrl);

              final gross = basic + hra + allowances;
              final pfAmount = basic * pfPercent / 100;
              final netSalary = gross - pfAmount - deductions;

              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;

              // Common input decoration.
              InputDecoration decoration(
                  String label, {
                    IconData? icon,
                    String? hint,
                    String? suffix,
                  }) {
                return InputDecoration(
                  labelText: label,
                  hintText: hint,
                  suffixText: suffix,
                  prefixIcon: icon == null
                      ? null
                      : Icon(icon, size: 16),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 42,
                  ),
                  labelStyle: const TextStyle(fontSize: 11.5),
                  hintStyle: const TextStyle(fontSize: 11),
                  suffixStyle: const TextStyle(fontSize: 11),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 0,
                  ),
                  constraints: const BoxConstraints(
                    minHeight: 42,
                    maxHeight: 42,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 1.2,
                    ),
                  ),
                  errorStyle: const TextStyle(fontSize: 9),
                );
              }


              Widget input(
                  TextEditingController controller,
                  String label, {
                    IconData? icon,
                    TextInputType keyboard = TextInputType.text,
                    String? suffix,
                    String? Function(String?)? validator,
                    int maxLines = 1,
                    bool readOnly = false,
                    bool isDecimal = false,
                  }) {
                return SizedBox(
                  height: maxLines > 1 ? null : 46,
                  child: TextFormField(
                    controller: controller,
                    readOnly: readOnly,
                    maxLines: maxLines,
                    keyboardType: keyboard,
                    inputFormatters: isDecimal
                        ? [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ]
                        : null,
                    validator: validator,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 12),
                    decoration: decoration(
                      label,
                      icon: icon,
                      suffix: suffix,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                );
              }

              // Section card.
              Widget section(
                  String title,
                  String subtitle,
                  IconData icon,
                  List<Widget> children,
                  ) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              icon,
                              color: theme.colorScheme.primary,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...children,
                    ],
                  ),
                );
              }

              // Responsive two-column field row.
              Widget fieldRow(Widget first, Widget second) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 480) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            first,
                            const SizedBox(height: 12),
                            second,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: first),
                          const SizedBox(width: 12),
                          Expanded(child: second),
                        ],
                      );
                    },
                  ),
                );
              }

              Widget salaryItem(String label, String value) {
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 760,
                  height: MediaQuery.of(context).size.height * 0.88,
                  child: Column(
                    children: [
                      // Header.
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                        color: theme.colorScheme.primary,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.badge_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isNew ? 'Add Employee' : 'Edit Employee',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isNew
                                        ? 'Create a new employee profile'
                                        : 'Update employee information',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(context).pop<int>(null),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form content.
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(17),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Personal information.
                                section(
                                  'Personal Information',
                                  'Basic employee contact details',
                                  Icons.person_outline,
                                  [
                                    fieldRow(
                                      input(
                                        codeCtrl,
                                        'Employee Code *',
                                        icon: Icons.tag,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Employee code required';
                                          }
                                          return null;
                                        },
                                      ),
                                      input(
                                        nameCtrl,
                                        'Full Name *',
                                        icon: Icons.person_outline,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Name is required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    fieldRow(
                                      input(
                                        emailCtrl,
                                        'Email Address',
                                        icon: Icons.email_outlined,
                                        keyboard: TextInputType.emailAddress,
                                        validator: (v) {
                                          if (v != null &&
                                              v.isNotEmpty &&
                                              !RegExp(
                                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                              ).hasMatch(v)) {
                                            return 'Enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      input(
                                        phoneCtrl,
                                        'Phone Number',
                                        icon: Icons.phone_outlined,
                                        keyboard: TextInputType.phone,
                                      ),
                                    ),
                                    input(
                                      addressCtrl,
                                      'Address',
                                      icon: Icons.location_on_outlined,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),

                                // Employment details.
                                section(
                                  'Employment Details',
                                  'Department, role and reporting structure',
                                  Icons.work_outline,
                                  [
                                    fieldRow(
                                      CustomDropdown<String>(
                                        label: 'Department',
                                        value: deptCtrl.text.isEmpty
                                            ? departmentOptions.first
                                            : deptCtrl.text,
                                        icon: Icons.apartment,
                                        items: [
                                          for (final department
                                          in departmentOptions)
                                            DropdownMenuItem(
                                              value: department,
                                              child: Text(
                                                department,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            deptCtrl.text = value ?? '';
                                          });
                                        },
                                      ),
                                      input(
                                        desigCtrl,
                                        'Designation',
                                        icon: Icons.work_outline,
                                      ),
                                    ),
                                    fieldRow(
                                      CustomDropdown<String>(
                                        label: 'Branch Office *',
                                        value: branch,
                                        icon: Icons.business_outlined,
                                        items: [
                                          for (final b in branchOptions)
                                            DropdownMenuItem(
                                              value: b,
                                              child: Text(
                                                b,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            branch =
                                                value ?? branchOptions.first;
                                          });
                                        },
                                      ),
                                      CustomDropdown<String>(
                                        label: 'Employment Status',
                                        value: status,
                                        icon: Icons.toggle_on_outlined,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Active',
                                            child: Text('Active'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Inactive',
                                            child: Text('Inactive'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            status = value ?? 'Active';
                                          });
                                        },
                                      ),
                                    ),
                                    fieldRow(
                                      CustomDropdown<int?>(
                                        label: 'Reporting Manager',
                                        value: managerId,
                                        icon: Icons.supervisor_account_outlined,
                                        items: [
                                          const DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text('No Manager'),
                                          ),
                                          for (final e in managerOptions)
                                            DropdownMenuItem<int?>(
                                              value: e.i('id'),
                                              child: Text(
                                                e.s('name'),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            managerId = value;
                                          });
                                        },
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          final selectedDate =
                                          await showDatePicker(
                                            context: context,
                                            initialDate:
                                            DateTime.tryParse(joinDate) ??
                                                DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );

                                          if (selectedDate != null) {
                                            setState(() {
                                              joinDate = ymd(selectedDate);
                                            });
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: InputDecorator(
                                          decoration: decoration(
                                            'Joining Date',
                                            icon: Icons.calendar_month_outlined,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                joinDate,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Icon(
                                                Icons.edit_calendar_outlined,
                                                size: 17,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Bank information.
                                section(
                                  'Bank Information',
                                  'Employee banking details',
                                  Icons.account_balance_outlined,
                                  [
                                    input(
                                      bankCtrl,
                                      'Bank Account Number',
                                      icon: Icons.account_balance,
                                      keyboard: TextInputType.number,
                                    ),
                                  ],
                                ),

                                // Salary structure.
                                section(
                                  'Salary Structure',
                                  'Monthly salary and deductions (INR)',
                                  Icons.currency_rupee,
                                  [
                                    fieldRow(
                                      input(
                                        basicCtrl,
                                        'Basic Salary',
                                        icon: Icons.currency_rupee,
                                        keyboard:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        isDecimal: true,
                                      ),
                                      input(
                                        hraCtrl,
                                        'House Rent Allowance',
                                        icon: Icons.home_work_outlined,
                                        keyboard:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        isDecimal: true,
                                      ),
                                    ),
                                    fieldRow(
                                      input(
                                        allowancesCtrl,
                                        'Other Allowances',
                                        icon: Icons.payments_outlined,
                                        keyboard:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        isDecimal: true,
                                      ),
                                      input(
                                        pfCtrl,
                                        'Employee PF Percentage',
                                        icon: Icons.percent,
                                        suffix: '%',
                                        keyboard:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        isDecimal: true,
                                      ),

                                    ),
                                    input(
                                      deductCtrl,
                                      'Other Deductions',
                                      icon: Icons.remove_circle_outline,
                                      keyboard:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      isDecimal: true,
                                    ),

                                    const SizedBox(height: 12),

                                    // Salary preview.
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'MONTHLY SALARY SUMMARY',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          Row(
                                            children: [
                                              salaryItem(
                                                'Gross Salary',
                                                '₹${nf(gross)}',
                                              ),
                                              salaryItem(
                                                'PF Deduction',
                                                '₹${nf(pfAmount)}',
                                              ),
                                              salaryItem(
                                                'Other Deduction',
                                                '₹${nf(deductions)}',
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 25),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Estimated Net Salary',
                                                      style: theme
                                                          .textTheme.bodyMedium
                                                          ?.copyWith(
                                                        fontSize: 12,
                                                        fontWeight:
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'After PF and other deductions',
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        fontSize: 10,
                                                        color: theme.colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '₹${nf(netSalary)}',
                                                style: theme
                                                    .textTheme.headlineSmall
                                                    ?.copyWith(
                                                  fontSize: 19,
                                                  color: netSalary < 0
                                                      ? theme.colorScheme.error
                                                      : Colors.green.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Footer.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Fields marked * are required',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(context).pop<int>(null),
                              style: OutlinedButton.styleFrom(
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 9),
                            FilledButton.icon(
                              onPressed: saving
                                  ? null
                                  : () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                setState(() {
                                  saving = true;
                                });

                                try {
                                  final Map<String, Object?> data = {
                                    'code': codeCtrl.text.trim(),
                                    'name': nameCtrl.text.trim(),
                                    'email': emailCtrl.text.trim(),
                                    'phone': phoneCtrl.text.trim(),
                                    'department': deptCtrl.text.trim(),
                                    'designation': desigCtrl.text.trim(),
                                    'branch': branch,
                                    'manager_id': managerId,
                                    'join_date': joinDate,
                                    'status': status,
                                    'address': addressCtrl.text.trim(),
                                    'bank_account': bankCtrl.text.trim(),
                                    'basic': amount(basicCtrl),
                                    'hra': amount(hraCtrl),
                                    'allowances': amount(allowancesCtrl),
                                    'pf_percent': amount(pfCtrl),
                                    'other_deduction': amount(deductCtrl),
                                  };

                                  final existingId = existing?.i('id');

                                  final savedId =
                                  await EmployeesRepository().saveEmployee(
                                    data,
                                    id: existingId,
                                  );

                                  if (!context.mounted) return;

                                  if (savedId <= 0) {
                                    throw StateError(
                                      'The save operation did not return '
                                          'a valid employee ID. Check '
                                          'LocalDatasource.saveData.',
                                    );
                                  }

                                  // Updates keep their existing primary key.
                                  // Inserts must return a valid new ID.
                                  final employeeId = existingId ?? savedId;

                                  if (employeeId <= 0) {
                                    throw StateError(
                                      'The save operation did not return '
                                          'a valid employee ID. Check '
                                          'LocalDatasource.saveData.',
                                    );
                                  }

                                  Navigator.of(dialogContext)
                                      .pop<int>(employeeId);
                                } catch (e, stackTrace) {
                                  debugPrint(
                                    'Unable to save employee: $e',
                                  );
                                  debugPrintStack(
                                    stackTrace: stackTrace,
                                  );

                                  if (!context.mounted) return;

                                  setState(() {
                                    saving = false;
                                  });

                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unable to save employee: $e',
                                        ),
                                        behavior:
                                        SnackBarBehavior.floating,
                                      ),
                                    );
                                }
                              },
                              icon: saving
                                  ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(
                                Icons.save_outlined,
                                size: 17,
                              ),
                              label: Text(
                                saving ? 'Saving...' : 'Save Employee',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    return result;
  } catch (_) {
    // Handles failures before the dialog can take ownership.
    // The owner widget disposes controllers after it is mounted.
    rethrow;
  }
}

// ============================================================
// CONTROLLER LIFECYCLE OWNER
// ============================================================

class _EmployeeFormControllerOwner extends StatefulWidget {
  final List<TextEditingController> controllers;
  final Widget child;

  const _EmployeeFormControllerOwner({
    required this.controllers,
    required this.child,
  });

  @override
  State<_EmployeeFormControllerOwner> createState() =>
      _EmployeeFormControllerOwnerState();
}

class _EmployeeFormControllerOwnerState
    extends State<_EmployeeFormControllerOwner> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


