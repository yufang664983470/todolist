import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() => runApp(const TodoApp());

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoItem {
  String id;
  String title;
  String content;
  DateTime reminderTime;
  bool isCompleted;
  int urgencyLevel;

  TodoItem({
    required this.id,
    required this.title,
    required this.content,
    required this.reminderTime,
    required this.urgencyLevel,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'reminderTime': reminderTime.toIso8601String(),
    'urgencyLevel': urgencyLevel,
    'isCompleted': isCompleted,
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    urgencyLevel: json['urgencyLevel'],
    reminderTime: DateTime.parse(json['reminderTime']),
    isCompleted: json['isCompleted'],
  );
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<TodoItem> _todoItems = [];
  final String _storageKey = 'todoItems';

  @override
  void initState() {
    super.initState();
    _loadTodoItems();
  }

  Future<void> _loadTodoItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        _todoItems = jsonList
            .map((item) => TodoItem.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _saveTodoItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(
      _todoItems.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_storageKey, jsonString);
  }

  void _addTodoItem(TodoItem newItem) {
    setState(() {
      _todoItems.add(newItem);
      _todoItems.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    });
    _saveTodoItems();
  }

  void _deleteTodoItem(String itemId) {
    setState(() {
      _todoItems.removeWhere((item) => item.id == itemId);
    });
    _saveTodoItems();
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2: return Colors.red;
      case 1: return Colors.orange;
      default: return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('待办事项'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final newItem = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTodoScreen(),
                ),
              );
              if (newItem != null) {
                _addTodoItem(newItem);
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _todoItems.length,
        itemBuilder: (context, index) {
          final item = _todoItems[index];
          return Dismissible(
            key: Key(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) => _deleteTodoItem(item.id),
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(item.urgencyLevel)
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                '提醒时间: ${DateFormat('yyyy-MM-dd HH:mm').format(item.reminderTime)}',
              ),
              trailing: Checkbox(
                value: item.isCompleted,
                onChanged: (value) {
                  setState(() {
                    item.isCompleted = value ?? false;
                  });
                  _saveTodoItems();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  _AddTodoScreenState createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _urgencyLevel = 0;
  final List<String> data = ['普通', '紧急' ,'非常紧急'];
  late String _dropdownValue = data.first;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _onSelect(String? value) {
    setState(() {
      _dropdownValue = value!;
      _urgencyLevel = data.indexOf(_dropdownValue);
    });
  }

  List<DropdownMenuEntry<String>> _buildMenuList(List<String> data) {
    return data.map((String value) {
      return DropdownMenuEntry<String>(value: value, label: value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加新事项')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                  hintText: '请输入事项标题',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '标题不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '内容',
                  border: OutlineInputBorder(),
                  hintText: '请输入事项详情',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '内容不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('紧急程度：'),
                  DropdownMenu<String>(
                    menuHeight: 200,
                    initialSelection: data.first,
                    onSelected: _onSelect,
                    dropdownMenuEntries: _buildMenuList(data),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('选择日期'),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectDate,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ListTile(
                      title: const Text('选择时间'),
                      subtitle: Text(_selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: _selectTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final DateTime reminderDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );
                    Navigator.pop(
                      context,
                      TodoItem(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        title: _titleController.text,
                        content: _contentController.text,
                        urgencyLevel: _urgencyLevel,
                        reminderTime: reminderDateTime,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('确认添加'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
