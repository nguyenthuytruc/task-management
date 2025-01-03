import 'package:flutter/material.dart';
import 'package:frontend/models/api_TaskService.dart';
import 'package:frontend/models/api_listService.dart';
import 'package:frontend/screen/TaskDetail_Screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListScreen extends StatefulWidget {
  final String boardId;

  ListScreen({required this.boardId});

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ApiListService _apiListService = ApiListService();
  final ApiTaskService _apiTaskService = ApiTaskService();
  late Future<List<dynamic>> _lists;
  late String _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getUserId();
    _lists = _apiListService.getAllLists(widget.boardId);
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('idUser') ?? '';
    });
  }

  Future<List<dynamic>> _getTasksForList(String listId) async {
    try {
      return await _apiTaskService.getAllTasksByListId(listId);
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text('Danh sách của bạn'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _lists,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Không có danh sách nào."));
          } else {
            var lists = snapshot.data!;
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: lists.length,
              itemBuilder: (context, index) {
                var list = lists[index];
                return Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Card(
                    color: Colors.white,
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  list['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_horiz),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditListDialog(list);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmationDialog(list['_id']);
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
                          SizedBox(height: 5),
                          Text(
                            list['description'] ?? 'Không có mô tả',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 10),
                          FutureBuilder<List<dynamic>>(
                            future: _getTasksForList(list['_id']),
                            builder: (context, taskSnapshot) {
                              if (taskSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (taskSnapshot.hasError) {
                                return Text('Lỗi: ${taskSnapshot.error}');
                              } else if (!taskSnapshot.hasData ||
                                  taskSnapshot.data!.isEmpty) {
                                return Text('Không có task nào.');
                              } else {
                                var tasks = taskSnapshot.data!;
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxHeight: 200.0),
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics: BouncingScrollPhysics(),
                                          itemCount: tasks.length,
                                          itemBuilder: (context, taskIndex) {
                                            var task = tasks[taskIndex];
                                            return ListTile(
                                              title: Text(task['name']),
                                              subtitle: Text(
                                                  task['description'] ??
                                                      'Không có mô tả'),
                                              onTap: () async {
                                                try {
                                                  final taskDetails =
                                                      await _apiTaskService
                                                          .getTaskById(
                                                              task['_id']);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          TaskDetailScreen(
                                                              taskId:
                                                                  task['_id']),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Không thể tải chi tiết task: $e')),
                                                  );
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              _showAddTaskDialog(list['_id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddListDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  // Hiển thị hộp thoại thêm task
  void _showAddTaskDialog(String listId) {
    String taskName = "";
    String taskDescription = "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Thêm task mới"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: "Tên task",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  taskName = value;
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: "Mô tả (không bắt buộc)",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  taskDescription = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại
              },
              child: Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (taskName.isNotEmpty) {
                  await _addTaskToList(listId, taskName, taskDescription);
                  Navigator.pop(context); // Đóng hộp thoại
                  setState(() {
                    _lists = _apiListService
                        .getAllLists(widget.boardId); // Làm mới danh sách
                  });
                }
              },
              child: Text("Thêm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addTaskToList(
      String listId, String name, String description) async {
    try {
      final taskData = {
        'name': name,
        'description': description,
        'listId': listId,
        'createdBy': _userId, // Sử dụng idUser khi tạo task
      };

      final newTask = await _apiTaskService.createTask(taskData);

      if (newTask != null && newTask['data'] != null) {
        setState(() {
          // Cập nhật trực tiếp danh sách task cho danh sách cụ thể
          _lists = _lists.then((lists) {
            return lists.map((list) {
              if (list['_id'] == listId) {
                if (list['tasks'] == null) list['tasks'] = [];
                list['tasks'].add(newTask['data']);
              }
              return list;
            }).toList();
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo task mới thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Thêm task thất bại: Không có dữ liệu trả về')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thêm task thất bại: $e')),
      );
    }
  }

  // Hiển thị hộp thoại thêm danh sách mới
  void _showAddListDialog() {
    String newListName = "";
    String newListDescription = "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Thêm danh sách mới"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: "Tên danh sách",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  newListName = value;
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: "Mô tả (không bắt buộc)",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  newListDescription = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại
              },
              child: Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newListName.isNotEmpty) {
                  await _addNewList(
                      newListName, newListDescription); // Gọi API để thêm
                  Navigator.pop(context); // Đóng hộp thoại
                  setState(() {
                    _lists = _apiListService
                        .getAllLists(widget.boardId); // Làm mới danh sách
                  });
                }
              },
              child: Text("Thêm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewList(String name, String description) async {
    try {
      final listData = {
        'name': name,
        'description': description,
        'boardId': widget.boardId,
        'createdBy': _userId, // Sử dụng idUser khi tạo danh sách
      };

      final newList = await _apiListService.createList(listData);

      // In phản hồi từ API để kiểm tra
      print('API response: $newList');

      // Kiểm tra nếu có dữ liệu hợp lệ từ API
      if (newList != null && newList['data'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo danh sách mới thành công!')),
        );
      } else {
        // Nếu không có dữ liệu hợp lệ từ API, hiển thị thông báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Thêm danh sách thất bại: Không có dữ liệu trả về')),
        );
      }
    } catch (e) {
      // In ra chi tiết lỗi để debug
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thêm danh sách thất bại: $e')),
      );
    }
  }
// Hộp thoại chỉnh sửa danh sách

  void _showEditListDialog(Map<String, dynamic> list) {
    String updatedName = list['name'];
    String updatedDescription = list['description'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Chỉnh sửa danh sách"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: "Tên danh sách",
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: updatedName),
                onChanged: (value) {
                  updatedName = value;
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: "Mô tả (không bắt buộc)",
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: updatedDescription),
                onChanged: (value) {
                  updatedDescription = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại
              },
              child: Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (updatedName.isNotEmpty) {
                  await _updateList(
                      list['_id'], updatedName, updatedDescription);
                  Navigator.pop(context); // Đóng hộp thoại
                  setState(() {
                    _lists = _apiListService
                        .getAllLists(widget.boardId); // Làm mới danh sách
                  });
                }
              },
              child: Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateList(String id, String name, String description) async {
    try {
      final updatedData = {
        'name': name,
        'description': description,
      };

      final response = await _apiListService.updateList(id, updatedData);

      // Kiểm tra phản hồi từ server
      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật danh sách thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật danh sách thất bại!')),
        );
      }
    } catch (e) {
      // Xử lý lỗi nếu gặp phải
      print('Error updating list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi cập nhật danh sách!')),
      );
    }
  }

  void _showDeleteConfirmationDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Xác nhận xóa"),
          content: Text("Bạn có chắc chắn muốn xóa danh sách này không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại
              },
              child: Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Đóng hộp thoại
                bool success = await _apiListService.deleteList(id);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Xóa thành công!")),
                  );
                  setState(() {
                    _lists = _apiListService
                        .getAllLists(widget.boardId); // Làm mới danh sách
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Xóa thất bại!")),
                  );
                }
              },
              child: Text("Xóa"),
            ),
          ],
        );
      },
    );
  }
}
