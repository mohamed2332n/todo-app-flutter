import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dotenv/dotenv.dart' show load, env;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await load();
  
  await Supabase.initialize(
    url: env['SUPABASE_URL']!,
    anonKey: env['SUPABASE_ANON_KEY']!,
  );

  runApp(const TodoApp());
}

final supabase = Supabase.instance.client;

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TodoList(),
    );
  }
}

class Todo {
  final String id;
  String text;
  bool isDone;

  Todo({
    required this.id,
    required this.text,
    this.isDone = false,
  });
}

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final List<Todo> _todos = [];
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final data = await supabase.from('todos').select();
    setState(() {
      _todos.clear();
      for (var item in data) {
        _todos.add(Todo(
          id: item['id'],
          text: item['text'],
          isDone: item['is_done'] ?? false,
        ));
      }
    });
  }

  Future<void> _addTodo() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    final response = await supabase.from('todos').insert({
      'text': text,
      'is_done': false,
    }).select().single();
    
    setState(() {
      _todos.add(Todo(
        id: response['id'],
        text: response['text'],
        isDone: response['is_done'] ?? false,
      ));
    });
    _textController.clear();
  }

  Future<void> _toggleTodo(String id) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    final newStatus = !todo.isDone;
    
    await supabase.from('todos').update({
      'is_done': newStatus,
    }).eq('id', id);
    
    setState(() {
      todo.isDone = newStatus;
    });
  }

  Future<void> _deleteTodo(String id) async {
    await supabase.from('todos').delete().eq('id', id);
    setState(() {
      _todos.removeWhere((t) => t.id == id);
    });
  }

  void _editTodo(String id) {
    final todo = _todos.firstWhere((t) => t.id == id);
    _textController.text = todo.text;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Todo'),
        content: TextField(
          controller: _textController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Task'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newText = _textController.text.trim();
              if (newText.isNotEmpty) {
                await supabase.from('todos').update({
                  'text': newText,
                }).eq('id', id);
                setState(() => todo.text = newText);
                _textController.clear();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final undone = _todos.where((t) => !t.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo App'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$undone / ${_todos.length}',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
        ],
      ),
      body: _todos.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No tasks yet', style: theme.textTheme.titleMedium),
                  Text('Add one using the button below',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _todos.length,
              itemBuilder: (ctx, i) {
                final todo = _todos[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isDone,
                      onChanged: (_) => _toggleTodo(todo.id),
                    ),
                    title: Text(
                      todo.text,
                      style: TextStyle(
                        decoration: todo.isDone ? TextDecoration.lineThrough : null,
                        color: todo.isDone ? theme.colorScheme.outline : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editTodo(todo.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteTodo(todo.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Add Todo'),
              content: TextField(
                controller: _textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'What needs to be done?',
                ),
                onSubmitted: (_) => _addTodo(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _textController.clear();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    _addTodo();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}