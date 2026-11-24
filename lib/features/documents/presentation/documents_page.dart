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
            'Could not open the file chooser: $e. On macOS, add the file-access entitlement.');
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
    final narrow = MediaQuery.of(context).size.width < 800;

    return PageBox(
      child: Column(
        children: [
          Header(
            'Documents',
            actions: [
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.upload_file, size: 16),
                label: Text(narrow ? 'Upload' : 'Upload Document'),
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
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = _controller.documents;

                if (docs.isEmpty) {
                  return const Center(child: Text('No documents uploaded.'));
                }

                if (narrow) {
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final d = docs[index];
                      return Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(
                                  Icons.insert_drive_file_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.s('title'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${d.s('emp_name')} • ${d.s('category')} • ${fmtDate(d['added_on'])}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Open',
                                icon: const Icon(Icons.open_in_new, size: 18),
                                onPressed: () async {
                                  if (await File(d.s('file_path')).exists()) {
                                    await openFile(d.s('file_path'));
                                  } else if (mounted) {
                                    toast(context, 'File not found on disk');
                                  }
                                },
                              ),
                              if (Session.isHr ||
                                  d['employee_id'] == Session.empId)
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    if (await confirm(context,
                                        'Delete document?', d.s('title'))) {
                                      await _controller.deleteDocument(d);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return TableCard(
                  columns: const [
                    DataColumn(
                        label: Text('Employee',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(
                        label: Text('Title',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(
                        label: Text('Category',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(
                        label: Text('Added',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final d in docs)
                      DataRow(
                        cells: [
                          DataCell(Text(d.s('emp_name'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
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
                            if (Session.isHr ||
                                d['employee_id'] == Session.empId)
                              IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    if (await confirm(context,
                                        'Delete document?', d.s('title'))) {
                                      await _controller.deleteDocument(d);
                                    }
                                  }),
                          ])),
                        ],
                      ),
                  ],
                  empty: 'No documents uploaded.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
