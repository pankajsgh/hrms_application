import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'ui.dart';

String _rs(num v) {
  final s = v.toStringAsFixed(2);
  final parts = s.split('.');
  final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return 'Rs. $whole.${parts[1]}';
}

pw.Widget _cell(String t, {bool bold = false, pw.TextAlign? align}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(t,
          textAlign: align,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );

pw.TableRow _row(String a, String b, {bool bold = false}) => pw.TableRow(
    children: [_cell(a, bold: bold), _cell(b, bold: bold, align: pw.TextAlign.right)]);

/// Builds a payslip PDF for a payroll row and asks where to save it.
Future<void> savePayslip(BuildContext context, dynamic p) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(kCompany,
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Payslip for ${monthLabel(p.s('month'))}',
              style: const pw.TextStyle(fontSize: 12)),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey600), children: [
            _row('Employee', p.s('name')),
            _row('Employee code', p.s('code')),
            _row('Department', p.s('department')),
            _row('Designation', p.s('designation')),
            _row('Bank account', p.s('bank_account')),
            _row('Working days', nf(p.d('working_days'))),
            _row('Paid days', nf(p.d('paid_days'))),
          ]),
          pw.SizedBox(height: 16),
          pw.Text('Earnings',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey600), children: [
            _row('Basic', _rs(p.d('basic'))),
            _row('House rent allowance', _rs(p.d('hra'))),
            _row('Other allowances', _rs(p.d('allowances'))),
            _row('Gross earnings', _rs(p.d('gross')), bold: true),
          ]),
          pw.SizedBox(height: 16),
          pw.Text('Deductions',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey600), children: [
            _row('Provident fund', _rs(p.d('pf'))),
            _row('Other deductions', _rs(p.d('other_deduction'))),
            _row('Total deductions',
                _rs(p.d('pf') + p.d('other_deduction')),
                bold: true),
          ]),
          pw.SizedBox(height: 16),
          pw.Container(
            color: PdfColors.grey200,
            child: pw.Table(children: [
              _row('NET PAY', _rs(p.d('net')), bold: true),
            ]),
          ),
          pw.Spacer(),
          pw.Text('This is a computer generated payslip.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    ),
  );

  final bytes = await doc.save();
  final name = 'payslip_${p.s('code')}_${p.s('month')}.pdf';
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save payslip',
    fileName: name,
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  if (path == null) return;
  final target = path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
  try {
    await File(target).writeAsBytes(bytes);
    if (context.mounted) toast(context, 'Saved: $target');
  } catch (e) {
    if (context.mounted) toast(context, 'Could not save: $e');
  }
}
