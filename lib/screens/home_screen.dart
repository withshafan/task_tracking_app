import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
import '../repositories/task_repository.dart';
import '../models/user.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/add_task_sheet.dart';
import 'task_detail_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TaskRepository _taskRepo = TaskRepository();
  bool _hasInitializedTasks = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTaskBottomSheet(AppUser currentUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddTaskSheet(
          currentUser: currentUser,
          onTaskAdded: (newTask) async {
            await _taskRepo.addTask(newTask);
          },
        );
      },
    );
  }

  Widget _buildTasksTab(AppUser currentUser) {
    final taskProvider = context.watch<TaskProvider>();

    if (!_hasInitializedTasks) {
      // Trigger the listener for tasks
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TaskProvider>().listenToTasks(
              isAdmin: currentUser.isAdmin,
              userEmail: currentUser.email,
            );
      });
      _hasInitializedTasks = true;
    }

    final filteredTasks = taskProvider.filtered(
      status: _selectedFilter,
      query: _searchQuery,
    );

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tasks...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(currentUser.isAdmin ? 'All Tasks (Admin)' : 'My Tasks'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('All', 'all'),
                const SizedBox(width: 8),
                _filterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _filterChip('In Progress', 'in progress'),
                const SizedBox(width: 8),
                _filterChip('Completed', 'completed'),
              ],
            ),
          ),
          // Task List
          Expanded(
            child: taskProvider.isLoading
                ? const LoadingShimmer()
                : taskProvider.error != null
                    ? Center(child: Text('Error: ${taskProvider.error}'))
                    : filteredTasks.isEmpty
                        ? EmptyState(
                            icon: Icons.assignment_outlined,
                            title: _searchQuery.isNotEmpty ? 'No search results' : 'No tasks yet',
                            description: _searchQuery.isNotEmpty
                                ? 'Try searching for something else'
                                : 'Get started by creating your first task!',
                            onActionPressed: () => _showAddTaskBottomSheet(currentUser),
                            actionLabel: 'Create Task',
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              context.read<TaskProvider>().listenToTasks(
                                    isAdmin: currentUser.isAdmin,
                                    userEmail: currentUser.email,
                                  );
                            },
                            child: ListView.builder(
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                return TaskCard(
                                  task: task,
                                  index: index,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TaskDetailScreen(task: task),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskBottomSheet(currentUser),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (userProvider.isLoading || userProvider.appUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUser = userProvider.appUser!;

    final List<Widget> pages = [
      _buildTasksTab(currentUser),
      StatsScreen(currentUser: currentUser),
      ProfileScreen(currentUser: currentUser),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
