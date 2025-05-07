// lib/widgets/data_table_widget.dart
import 'package:flutter/material.dart';

class DataTableWidget extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;

  const DataTableWidget({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns.map((column) => DataColumn(label: Text(column))).toList(),
        rows: rows
            .map((row) => DataRow(
                  cells: row.map((cell) => DataCell(Text(cell))).toList(),
                ))
            .toList(),
      ),
    );
  }
}
