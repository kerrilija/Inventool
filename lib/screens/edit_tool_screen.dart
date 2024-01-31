import 'package:flutter/material.dart';
import 'package:tool_crib/models/tool.dart';
import 'package:postgres/postgres.dart';
import 'package:tool_crib/widgets/search_widget.dart';
import 'package:tool_crib/widgets/tool_form.dart';

class EditToolScreen extends StatefulWidget {
  final PostgreSQLConnection connection;

  EditToolScreen({required this.connection});

  @override
  _EditToolScreenState createState() => _EditToolScreenState();
}

class _EditToolScreenState extends State<EditToolScreen> {
  Tool? selectedTool;

  void selectToolForEditing(Tool tool) {
    setState(() {
      selectedTool = tool;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedTool != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit Tool')),
        body: SingleChildScrollView(
          child: ToolForm(
            initialTool: selectedTool,
            connection: widget.connection,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Search Tools')),
      body: ToolSearchWidget(
        connection: widget.connection,
        actionTypes: const [ToolAction.Edit],
        onEdit: selectToolForEditing,
      ),
    );
  }
}
