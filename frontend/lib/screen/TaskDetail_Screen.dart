import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  TaskDetailScreen({required this.taskId});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? taskData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/task/${widget.taskId}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          taskData = jsonData['data']['list'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Không thể tải task: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _deleteTask() async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:3000/api/task/delete/${widget.taskId}'),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Quay lại màn hình trước đó
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa task: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa task: $e')),
      );
    }
  }

  void _showEditDialog() {
    // Mở dialog để chỉnh sửa task
    showDialog(
      context: context,
      builder: (context) {
        String updatedName = taskData?['name'] ?? '';
        String updatedDescription = taskData?['description'] ?? '';

        return AlertDialog(
          title: Text('Chỉnh sửa Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Tên Task'),
                controller: TextEditingController(text: updatedName),
                onChanged: (value) => updatedName = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Mô tả Task'),
                controller: TextEditingController(text: updatedDescription),
                onChanged: (value) => updatedDescription = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  final response = await http.put(
                    Uri.parse('http://10.0.2.2:3000/api/task/${widget.taskId}'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'name': updatedName,
                      'description': updatedDescription,
                    }),
                  );

                  if (response.statusCode == 200) {
                    setState(() {
                      taskData?['name'] = updatedName;
                      taskData?['description'] = updatedDescription;
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Không thể chỉnh sửa task: ${response.statusCode}')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi chỉnh sửa task: $e')),
                  );
                }
              },
              child: Text('Lưu'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(taskData?['name'] ?? 'Chi tiết Task'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog();
              } else if (value == 'delete') {
                _deleteTask();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text('Chỉnh sửa'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Xóa'),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tên Task: ${taskData?['name'] ?? 'Không có tên'}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mô tả: ${taskData?['description'] ?? 'Không có mô tả'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Người tạo: ${taskData?['createdBy'] ?? 'Không rõ'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Trạng thái: ${taskData?['status'] ?? 'Không rõ'}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
    );
  }
}
