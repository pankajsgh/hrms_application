import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hrms/comman_widget/customer_dropdown.dart';

import 'common.dart';

export 'common.dart';

const kCompany = 'My Company Pvt Ltd'; // shown on payslips

void toast(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

Future<bool> confirm(BuildContext c, String title, String msg) async {
  final ok = await showDialog<bool>(
    context: c,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(msg),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes')),
      ],
    ),
  );
  return ok == true;
}

Future<void> openFile(String path) async {
  if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', path]);
  } else if (Platform.isMacOS) {
    await Process.run('open', [path]);
  } else {
    await Process.run('xdg-open', [path]);
  }
}

Future<void> exportCsv(BuildContext context, String fileName,
    List<String> header, List<List<Object?>> rows) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save CSV',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  if (path == null) return;
  final target = path.toLowerCase().endsWith('.csv') ? path : '$path.csv';
  String q(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
  final sb = StringBuffer('﻿')..writeln(header.map(q).join(','));
  for (final r in rows) {
    sb.writeln(r.map(q).join(','));
  }
  try {
    await File(target).writeAsString(sb.toString());
    if (context.mounted) toast(context, 'Saved: $target');
  } catch (e) {
    if (context.mounted) toast(context, 'Could not save: $e');
  }
}

// ---------------------------------------------------------------- layout
/// Rounded white surface used instead of Card everywhere.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

/// Small coloured badge for statuses.
class StatusChip extends StatelessWidget {
  const StatusChip(this.text, {super.key});
  final String text;

  Color get _color {
    switch (text) {
      case 'Active':
      case 'Approved':
      case 'Present':
      case 'Completed':
      case 'Open':
      case 'Hired':
      case 'Selected':
        return Colors.green;
      case 'Pending':
      case 'Pending approval':
      case 'Half Day':
      case 'In Progress':
      case 'Applied':
      case 'Screening':
      case 'Interview':
      case 'On hold':
      case 'On Hold':
        return Colors.orange;
      case 'Rejected':
      case 'Absent':
      case 'Inactive':
      case 'Closed':
      case 'Unpaid Leave':
      case 'No show':
        return Colors.red;
      case 'Leave':
      case 'Offered':
      case 'Scheduled':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: Color.alphaBlend(Colors.black.withOpacity(0.25), c),
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class PageBox extends StatelessWidget {
  const PageBox({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
      padding:
          EdgeInsets.all(MediaQuery.of(context).size.width < 800 ? 12 : 16),
      child: child);
}

class Header extends StatelessWidget {
  const Header(this.title, {super.key, this.actions = const []});
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700))),
        for (final a in actions) ...[const SizedBox(width: 8), a],
      ]),
    );
  }
}

class TabsView extends StatelessWidget {
  const TabsView({super.key, required this.titles, required this.children});
  final List<String> titles;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: titles.length,
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            splashBorderRadius: BorderRadius.circular(12),
            tabs: [for (final t in titles) Tab(height: 40, text: t)],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: TabBarView(children: children)),
      ]),
    );
  }
}

class TableCard extends StatelessWidget {
  const TableCard(
      {super.key,
      required this.columns,
      required this.rows,
      this.empty = 'Nothing here yet.'});
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Panel(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inbox_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(empty, textAlign: TextAlign.center),
                  ]))));
    }
    return Panel(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth),
              child: DataTable(columns: columns, rows: rows),
            ),
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard(this.label, this.value, this.icon, this.color, {super.key});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 800 ? 150 : 210,
      child: Panel(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(label,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class MonthBar extends StatelessWidget {
  const MonthBar(
      {super.key,
      required this.year,
      required this.month,
      required this.onChanged});
  final int year, month;
  final void Function(int year, int month) onChanged;

  @override
  Widget build(BuildContext context) {
    void shift(int d) {
      final x = DateTime(year, month + d);
      onChanged(x.year, x.month);
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
          icon: const Icon(Icons.chevron_left), onPressed: () => shift(-1)),
      SizedBox(
        width: 150,
        child: Text(monthLabel(monthKey(year, month)),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
      ),
      IconButton(
          icon: const Icon(Icons.chevron_right), onPressed: () => shift(1)),
    ]);
  }
}

// ---------------------------------------------------------------- forms
class F {
  const F(this.key, this.label,
      {this.type = 'text', this.options, this.required = false, this.initial});

  /// type: text | multiline | number | date | password | dropdown
  final String key, label, type;
  final Map<String, String>? options;
  final bool required;
  final Object? initial;
}

Future<Map<String, Object?>?> formDialog(
    BuildContext context, String title, List<F> fields,
    {bool cancelable = true, String saveLabel = 'Save'}) {
  return showDialog<Map<String, Object?>>(
    context: context,
    barrierDismissible: cancelable,
    builder: (_) => _FormDialog(
        title: title,
        fields: fields,
        cancelable: cancelable,
        saveLabel: saveLabel),
  );
}

class _FormDialog extends StatefulWidget {
  const _FormDialog(
      {required this.title,
      required this.fields,
      required this.cancelable,
      required this.saveLabel});
  final String title, saveLabel;
  final List<F> fields;
  final bool cancelable;

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _key = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{};
  final _dd = <String, String?>{};

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      final init = f.initial?.toString() ?? '';
      if (f.type == 'dropdown') {
        _dd[f.key] =
            (f.options?.containsKey(init) ?? false) ? init : null;
      } else {
        _c[f.key] = TextEditingController(text: init);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(F f) async {
    final c = _c[f.key]!;
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(c.text) ?? DateTime.now(),
      firstDate: DateTime(1940),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => c.text = ymd(d));
  }

  Future<void> _pickTime(F f) async {
    final c = _c[f.key]!;
    final parts = c.text.split(':');
    final init = parts.length == 2
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 10,
            minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 10, minute: 0);
    final t = await showTimePicker(context: context, initialTime: init);
    if (t != null) {
      setState(() => c.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final out = <String, Object?>{};
    for (final f in widget.fields) {
      switch (f.type) {
        case 'dropdown':
          out[f.key] = _dd[f.key];
          break;
        case 'number':
          out[f.key] = double.tryParse(_c[f.key]!.text.trim());
          break;
        case 'date':
          final t = _c[f.key]!.text.trim();
          out[f.key] = t.isEmpty ? null : t;
          break;
        case 'password':
          out[f.key] = _c[f.key]!.text;
          break;
        default:
          out[f.key] = _c[f.key]!.text.trim();
      }
    }
    Navigator.pop(context, out);
  }

  Widget _field(F f) {
    final dec = InputDecoration(
      labelText: f.required ? '${f.label} *' : f.label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.2),
      ),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
    );
    String? req(String? v) =>
        f.required && (v == null || v.trim().isEmpty) ? 'Required' : null;
    Widget w;
    switch (f.type) {
      case 'dropdown':
        final options = f.options ?? {};
        w = CustomDropdown<String>(
          label: f.required ? '${f.label} *' : f.label,
          value: _dd[f.key],
          searchText: (id) => options[id] ?? id,
          hint: 'Select ${f.label}',
          items: [
            if (!f.required)
              const DropdownMenuItem<String>(
                  value: '', child: Text('— none —')),
            for (final e in options.entries)
              DropdownMenuItem<String>(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) =>
              setState(() => _dd[f.key] = (v == null || v.isEmpty) ? null : v),
        );
        break;
      case 'date':
        w = TextFormField(
          controller: _c[f.key],
          readOnly: true,
          decoration: dec.copyWith(
              suffixIcon: const Icon(Icons.calendar_today, size: 18)),
          onTap: () => _pickDate(f),
          validator: req,
        );
        break;
      case 'time':
        w = TextFormField(
          controller: _c[f.key],
          readOnly: true,
          decoration: dec.copyWith(
              suffixIcon: const Icon(Icons.access_time, size: 18)),
          onTap: () => _pickTime(f),
          validator: req,
        );
        break;
      case 'number':
        w = TextFormField(
          controller: _c[f.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: dec,
          validator: (v) {
            final r = req(v);
            if (r != null) return r;
            if (v != null && v.trim().isNotEmpty && double.tryParse(v.trim()) == null) {
              return 'Enter a number';
            }
            return null;
          },
        );
        break;
      case 'password':
        w = TextFormField(
            controller: _c[f.key],
            obscureText: true,
            decoration: dec,
            validator: req);
        break;
      case 'multiline':
        w = TextFormField(
            controller: _c[f.key],
            maxLines: 3,
            decoration: dec,
            validator: req);
        break;
      default:
        w = TextFormField(
            controller: _c[f.key], decoration: dec, validator: req);
    }
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: w);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _key,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(children: [for (final f in widget.fields) _field(f)]),
            ),
          ),
        ),
      ),
      actions: [
        if (widget.cancelable)
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(widget.saveLabel)),
      ],
    );
  }
}

/// Small month/day badge (used for holidays, special days, interviews).
class DateBadge extends StatelessWidget {
  const DateBadge(this.date, {super.key, this.highlight = false});
  final DateTime? date;
  final bool highlight;

  static const _m = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = highlight ? cs.primary : cs.secondaryContainer;
    final fg = highlight ? cs.onPrimary : cs.onSecondaryContainer;
    final d = date;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(d == null ? '' : _m[d.month - 1],
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        Text(d == null ? '' : '${d.day}',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: fg)),
      ]),
    );
  }
}
