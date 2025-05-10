// screens/task_list_screen.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';
import 'package:intl/intl.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_updateFilteredTasks);

    // Ajouter quelques tâches d'exemple
    tasks = [
      Task(
        title: 'Réunion d\'équipe',
        description: 'Préparer la présentation du projet',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        priority: 'Haute',
      ),
      Task(
        title: 'Faire les courses',
        description: 'Acheter des fruits, légumes et du pain',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        priority: 'Moyenne',
      ),
      Task(
        title: 'Payer les factures',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        priority: 'Normale',
      ),
    ];

    _updateFilteredTasks();
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateFilteredTasks);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredTasks() {
    setState(() {
      // Appliquer filtre par statut (Toutes, À faire, Terminées)
      if (_tabController.index == 0) {
        filteredTasks = List.from(tasks);
      } else if (_tabController.index == 1) {
        filteredTasks = tasks.where((task) => !task.isCompleted).toList();
      } else {
        filteredTasks = tasks.where((task) => task.isCompleted).toList();
      }

      // Appliquer filtre de recherche
      if (_searchQuery.isNotEmpty) {
        filteredTasks = filteredTasks
            .where((task) => task.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }

      // Trier par date d'échéance (nulls last)
      filteredTasks.sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    });
  }

  void _addTask(Task newTask) {
    setState(() {
      tasks.add(newTask);
      _updateFilteredTasks();
    });
  }

  void _editTask(Task task) async {
    final editedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );

    if (editedTask != null) {
      setState(() {
        final index = tasks.indexWhere((t) => t.id == editedTask.id);
        if (index != -1) {
          tasks[index] = editedTask;
          _updateFilteredTasks();
        }
      });
    }
  }

  void _deleteTask(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette tâche ?'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() {
                tasks.removeWhere((task) => task.id == id);
                _updateFilteredTasks();
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _toggleTask(String id) {
    setState(() {
      final index = tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        tasks[index] = tasks[index].copyWith(isCompleted: !tasks[index].isCompleted);
        _updateFilteredTasks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mes Tâches',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _updateFilteredTasks();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher une tâche...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _updateFilteredTasks();
                        });
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Toutes'),
                  Tab(text: 'À faire'),
                  Tab(text: 'Terminées'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Options de tri
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('Trier par date d\'échéance'),
                      onTap: () {
                        setState(() {
                          filteredTasks.sort((a, b) {
                            if (a.dueDate == null) return 1;
                            if (b.dueDate == null) return -1;
                            return a.dueDate!.compareTo(b.dueDate!);
                          });
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.priority_high),
                      title: const Text('Trier par priorité'),
                      onTap: () {
                        setState(() {
                          final priorityOrder = {
                            'Haute': 0,
                            'Moyenne': 1,
                            'Normale': 2,
                            'Basse': 3,
                          };
                          filteredTasks.sort((a, b) => priorityOrder[a.priority]!
                              .compareTo(priorityOrder[b.priority]!));
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.title),
                      title: const Text('Trier par titre'),
                      onTap: () {
                        setState(() {
                          filteredTasks.sort((a, b) => a.title.compareTo(b.title));
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: filteredTasks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune tâche trouvée',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez une nouvelle tâche pour commencer',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return TaskCard(
            task: task,
            onToggle: () => _toggleTask(task.id),
            onDelete: () => _deleteTask(task.id),
            onEdit: () => _editTask(task),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newTask = await Navigator.push<Task>(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskFormScreen(),
            ),
          );
          if (newTask != null) {
            _addTask(newTask);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle tâche'),
      ),
    );
  }
}