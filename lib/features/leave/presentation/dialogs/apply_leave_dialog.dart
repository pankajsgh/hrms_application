import 'package:flutter/material.dart';
import 'package:hrms/comman_widget/customer_dropdown.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/domain/entities/leave_entity.dart';
import 'package:hrms/features/leave/presentation/comman_widget/leave_widgets.dart';
import 'package:hrms/features/leave/presentation/leave_controller.dart';
import 'package:hrms/features/leave/data/leave_repository.dart';

Future<void> showApplyLeaveDialog(
    BuildContext context,
    LeaveController controller, {
      String? defaultTypeName,
    }) async {
  final empId = Session.empId;

  if (empId == null) {
    toast(context, 'Employee session not found');
    return;
  }

  final types = controller.leaveTypes.isNotEmpty
      ? controller.leaveTypes
      : await LeaveRepository().leaveTypes();

  if (!context.mounted) return;

  if (types.isEmpty) {
    toast(context, 'No leave types available');
    return;
  }

  final seenNames = <String>{};
  final uniqueTypes = <LeaveTypeEntity>[];
  for (final t in types) {
    final nameKey = t.name.trim().toLowerCase();
    if (seenNames.add(nameKey)) {
      uniqueTypes.add(t);
    }
  }

  List<LeaveTypeEntity> availableTypes;
  bool dropdownEnabled = true;

  if (defaultTypeName == 'home') {
    availableTypes = uniqueTypes
        .where((t) =>
            t.name.toLowerCase().contains('home') ||
            t.name.toLowerCase().contains('wfh'))
        .toList();
    dropdownEnabled = false;
  } else if (defaultTypeName == 'field') {
    availableTypes = uniqueTypes
        .where((t) =>
            t.name.toLowerCase().contains('field') ||
            t.name.toLowerCase().contains('outside'))
        .toList();
    dropdownEnabled = false;
  } else {
    availableTypes = uniqueTypes
        .where((t) =>
            !t.name.toLowerCase().contains('home') &&
            !t.name.toLowerCase().contains('wfh') &&
            !t.name.toLowerCase().contains('field') &&
            !t.name.toLowerCase().contains('outside'))
        .toList();
    dropdownEnabled = true;
  }

  if (availableTypes.isEmpty) {
    availableTypes = uniqueTypes;
  }

  final reasonController = TextEditingController();
  String? selectedType = availableTypes.first.id?.toString();

  bool isSingleDay = true;
  DateTime? fromDate;
  DateTime? toDate;
  bool isHalfDay = false;
  String halfDayType = 'First Half';

  try {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cs = Theme.of(context).colorScheme;

            Future<void> pickDate(bool isFrom) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isFrom
                    ? fromDate ?? DateTime.now()
                    : toDate ?? fromDate ?? DateTime.now(),
                firstDate: isFrom ? DateTime(2020) : fromDate ?? DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (picked == null) return;

              setDialogState(() {
                if (isFrom) {
                  fromDate = picked;
                  if (isSingleDay) {
                    toDate = picked;
                  } else if (toDate != null && toDate!.isBefore(picked)) {
                    toDate = picked;
                  }
                } else {
                  toDate = picked;
                }
              });
            }

            final dialogTitle = defaultTypeName == 'home'
                ? 'Apply Work From Home'
                : defaultTypeName == 'field'
                    ? 'Apply Work Outside (Field)'
                    : 'Apply Leave Request';
            final dialogIcon = defaultTypeName == 'home'
                ? Icons.home_work_outlined
                : defaultTypeName == 'field'
                    ? Icons.near_me_outlined
                    : Icons.beach_access_rounded;

            final fieldLabel =
                defaultTypeName != null ? 'Request Type' : 'Leave Type';

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      dialogIcon,
                      color: cs.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dialogTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 7),
                      CustomDropdown<String>(
                        label: fieldLabel,
                        value: selectedType,
                        enabled: dropdownEnabled,
                        icon: Icons.category_outlined,
                        hint: 'Select type',
                        searchText: (id) {
                          final index = availableTypes.indexWhere(
                            (e) => e.id.toString() == id,
                          );
                          return index == -1 ? id : availableTypes[index].name;
                        },
                        items: [
                          for (final type in availableTypes)
                            if (type.id != null)
                              DropdownMenuItem<String>(
                                value: type.id.toString(),
                                child: Text(
                                  type.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                        ],
                        onChanged: (value) {
                          if (dropdownEnabled) {
                            setDialogState(() => selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('Duration Type'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Single Day',
                                  style: TextStyle(fontSize: 12.5)),
                              value: true,
                              groupValue: isSingleDay,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    isSingleDay = val;
                                    if (isSingleDay && fromDate != null) {
                                      toDate = fromDate;
                                    } else {
                                      isHalfDay = false;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Multiple Days',
                                  style: TextStyle(fontSize: 12.5)),
                              value: false,
                              groupValue: isSingleDay,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    isSingleDay = val;
                                    isHalfDay = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const FieldLabel('Leave Date(s)'),
                      const SizedBox(height: 7),
                      if (isSingleDay)
                        DateSelector(
                          label: 'Leave Date',
                          date: fromDate,
                          icon: Icons.calendar_today_rounded,
                          onTap: () => pickDate(true),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: DateSelector(
                                label: 'From Date',
                                date: fromDate,
                                icon: Icons.calendar_today_rounded,
                                onTap: () => pickDate(true),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: DateSelector(
                                label: 'To Date',
                                date: toDate,
                                icon: Icons.event_rounded,
                                onTap: () => pickDate(false),
                              ),
                            ),
                          ],
                        ),
                      if (fromDate != null && toDate != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: cs.primary,
                                size: 17,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                '${toDate!.difference(fromDate!).inDays + 1} calendar days selected',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSingleDay) ...[
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  title: const Text('Half Day Request',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  value: isHalfDay,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      isHalfDay = val ?? false;
                                    });
                                  },
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                                if (isHalfDay) ...[
                                  const Divider(height: 1),
                                  RadioListTile<String>(
                                    title: const Text('First Half',
                                        style: TextStyle(fontSize: 12.5)),
                                    value: 'First Half',
                                    groupValue: halfDayType,
                                    dense: true,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setDialogState(
                                            () => halfDayType = val);
                                      }
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: const Text('Second Half',
                                        style: TextStyle(fontSize: 12.5)),
                                    value: 'Second Half',
                                    groupValue: halfDayType,
                                    dense: true,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setDialogState(
                                            () => halfDayType = val);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 18),
                      const FieldLabel('Reason for Leave'),
                      const SizedBox(height: 7),
                      TextField(
                        controller: reasonController,
                        minLines: 3,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Enter reason for leave...',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 45),
                            child: Icon(Icons.notes_rounded, size: 18),
                          ),
                          filled: true,
                          fillColor:
                              cs.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: cs.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: cs.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: cs.primary,
                              width: 1.4,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    if (selectedType == null ||
                        fromDate == null ||
                        toDate == null ||
                        reasonController.text.trim().isEmpty) {
                      toast(context, 'Please complete all fields');
                      return;
                    }

                    if (toDate!.isBefore(fromDate!)) {
                      toast(context, 'Invalid leave dates');
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'type': selectedType,
                      'from': ymd(fromDate!),
                      'to': ymd(toDate!),
                      'reason': reasonController.text.trim(),
                      'isHalfDay': isHalfDay,
                      'halfDayType': halfDayType,
                    });
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !context.mounted) return;

    final error = await controller.applyLeave(
      empId,
      int.parse(result['type'] as String),
      DateTime.parse(result['from'] as String),
      DateTime.parse(result['to'] as String),
      result['reason'] as String,
      isHalfDay: result['isHalfDay'] == true,
      halfDayType: result['halfDayType'] as String?,
    );

    if (!context.mounted) return;

    toast(context, error ?? 'Leave request submitted successfully');
  } catch (e) {
    if (context.mounted) {
      toast(context, 'Unable to submit leave: $e');
    }
  } finally {
    reasonController.dispose();
  }
}
