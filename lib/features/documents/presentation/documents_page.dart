import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'documents_controller.dart';

class DocumentsFeaturePage extends StatefulWidget {
  const DocumentsFeaturePage({super.key});

  @override
  State<DocumentsFeaturePage> createState() => DocumentsFeaturePageState();
}

class DocumentsFeaturePageState extends State<DocumentsFeaturePage> {
  late final DocumentsController _controller;

  static const _cats = {
    'ID proof': 'ID proof',
    'Offer letter': 'Offer letter',
    'Contract': 'Contract',
    'Certificate': 'Certificate',
    'Resume': 'Resume',
    'Other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _controller = DocumentsController()..loadDocuments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    String? path;
    try {
      final pick = await FilePicker.platform.pickFiles();
      path = pick?.files.single.path;
    } catch (e) {
      if (mounted) {
        toast(context,
            'Could not open the file chooser: $e. On macOS, add the file-access entitlement (see README).');
      }
      return;
    }
    if (path == null) {
      if (mounted) toast(context, 'No file selected');
      return;
    }
    final chosen = path;
    final fileName = chosen.split(RegExp(r'[\\/]')).last;
    final emps = _controller.scopeEmployees;
    if (!mounted) return;
    final r = await formDialog(context, 'Upload: $fileName', [
      F('emp', 'Employee',
          type: 'dropdown',
          required: true,
          options: {for (final e in emps) '${e['id']}': e.s('name')},
          initial: Session.empId),
      F('title', 'Title', required: true, initial: fileName),
      const F('cat', 'Category',
          type: 'dropdown', required: true, options: _cats, initial: 'Other'),
    ], saveLabel: 'Upload');
    if (r == null) return;
    try {
      await _controller.addDocument(int.parse(r['emp'] as String),
          r['title'] as String, r['cat'] as String, chosen);
      if (mounted) toast(context, 'Document uploaded');
    } catch (e) {
      if (mounted) toast(context, 'Upload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBox(
      child: Column(children: [
        Header('Documents', actions: [
          FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload')),
        ]),
        Expanded(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return TableCard(
                columns: const [
                  DataColumn(label: Text('Employee')),
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Added')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final d in _controller.documents)
                    DataRow(cells: [
                      DataCell(Text(d.s('emp_name'))),
                      DataCell(Text(d.s('title'))),
                      DataCell(Text(d.s('category'))),
                      DataCell(Text(fmtDate(d['added_on']))),
                      DataCell(Row(children: [
                        IconButton(
                            tooltip: 'Open',
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () async {
                              if (await File(d.s('file_path')).exists()) {
                                await openFile(d.s('file_path'));
                              } else if (mounted) {
                                toast(context, 'File not found on disk');
                              }
                            }),
                        if (Session.isHr || d['employee_id'] == Session.empId)
                          IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (await confirm(
                                    context, 'Delete document?', d.s('title'))) {
                                  await _controller.deleteDocument(d);
                                }
                              }),
                      ])),
                    ]),
                ],
                empty: 'No documents uploaded.',
              );
            },
          ),
        ),
      ]),
    );
  }
}
