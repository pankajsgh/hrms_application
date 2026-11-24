import 'package:flutter/material.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/comman_widget/customer_dropdown.dart';

class DatabaseInspectorPage extends StatefulWidget {
  const DatabaseInspectorPage({super.key});

  @override
  State<DatabaseInspectorPage> createState() => _DatabaseInspectorPageState();
}

class _DatabaseInspectorPageState extends State<DatabaseInspectorPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<String> _tables = [
    'employees',
    'users',
    'attendance',
    'leave_types',
    'leaves',
    'holidays',
    'payroll',
    'jobs',
    'candidates',
    'interviews',
    'special_days',
    'goals',
    'reviews',
    'documents',
  ];

  String _selectedTable = 'employees';
  List<Map<String, Object?>> _rows = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _error;

  // SQL Console state
  final TextEditingController _sqlController = TextEditingController(
    text: 'SELECT * FROM employees LIMIT 50;',
  );
  List<Map<String, Object?>> _sqlResults = [];
  String? _sqlError;
  bool _isExecutingSql = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTableData(_selectedTable);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sqlController.dispose();
    super.dispose();
  }

  Future<void> _loadTableData(String table) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await Db.db.query(table);
      if (mounted) {
        setState(() {
          _rows = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _rows = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _executeSql() async {
    final query = _sqlController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isExecutingSql = true;
      _sqlError = null;
      _sqlResults = [];
    });

    try {
      final lower = query.toLowerCase();
      if (lower.startsWith('select') || lower.startsWith('pragma')) {
        final data = await Db.db.rawQuery(query);
        if (mounted) {
          setState(() {
            _sqlResults = data;
            _isExecutingSql = false;
          });
        }
      } else {
        final rowsAffected = await Db.db.rawUpdate(query);
        if (mounted) {
          setState(() {
            _sqlResults = [
              {'Message': 'Query executed successfully. Rows affected: $rowsAffected'}
            ];
            _isExecutingSql = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sqlError = e.toString();
          _isExecutingSql = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PageBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(
            'phpMyAdmin Style SQLite Inspector',
            actions: [
              SizedBox(
                width: 220,
                child: CustomDropdown<String>(
                  label: 'Table',
                  value: _selectedTable,
                  items: [
                    for (final t in _tables)
                      DropdownMenuItem<String>(
                        value: t,
                        child: Text(t, style: const TextStyle(fontSize: 13)),
                      ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTable = val);
                      _loadTableData(val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Refresh table data',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _loadTableData(_selectedTable),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: cs.onPrimary,
              unselectedLabelColor: cs.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Browse Table Data'),
                Tab(text: 'SQL Query Console'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(cs),
                _buildSqlConsoleTab(cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseTab(ColorScheme cs) {
    final filteredRows = _rows.where((row) {
      if (_searchQuery.isEmpty) return true;
      return row.values.any((val) =>
          val?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ??
          false);
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  onChanged: (q) => setState(() => _searchQuery = q.trim()),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Filter records in $_selectedTable...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Showing ${filteredRows.length} of ${_rows.length} rows',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
            child: Text(
              'Error loading table: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          )
              : filteredRows.isEmpty
              ? const Center(child: Text('No records found in this table.'))
              : Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _rows.isNotEmpty
                    ? _rows.first.keys.toList()
                    : <String>[];

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          cs.surfaceContainerHighest.withValues(alpha: 0.5)),
                      dataRowMinHeight: 38,
                      dataRowMaxHeight: 48,
                      columns: [
                        for (final col in columns)
                          DataColumn(
                            label: Text(
                              col,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                      rows: [
                        for (int i = 0; i < filteredRows.length; i++)
                          DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return cs.primary.withValues(alpha: 0.08);
                              }
                              return i.isEven ? Colors.white : Colors.grey.shade50;
                            }),
                            cells: [
                              for (final col in columns)
                                DataCell(
                                  Text(
                                    filteredRows[i][col]?.toString() ?? 'NULL',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontFamily: filteredRows[i][col] == null
                                          ? null
                                          : 'monospace',
                                      color: filteredRows[i][col] == null
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
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
        ),
      ],
    );
  }

  Widget _buildSqlConsoleTab(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Run Raw SQL Query',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _isExecutingSql ? null : _executeSql,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(_isExecutingSql ? 'Executing...' : 'Execute Query'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _sqlController,
          maxLines: 4,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          decoration: InputDecoration(
            hintText: 'Enter SQL query (e.g. SELECT * FROM employees)...',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Query Results',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isExecutingSql
              ? const Center(child: CircularProgressIndicator())
              : _sqlError != null
              ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'SQL Error: $_sqlError',
              style: TextStyle(
                  color: Colors.red.shade800,
                  fontFamily: 'monospace',
                  fontSize: 12),
            ),
          )
              : _sqlResults.isEmpty
              ? const Center(
              child: Text(
                  'No results to display. Run a SELECT query above.'))
              : Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                      cs.surfaceContainerHighest.withValues(alpha: 0.5)),
                  columns: [
                    for (final col in _sqlResults.first.keys)
                      DataColumn(
                        label: Text(
                          col,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                  rows: [
                    for (final row in _sqlResults)
                      DataRow(
                        cells: [
                          for (final val in row.values)
                            DataCell(
                              Text(
                                val?.toString() ?? 'NULL',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
