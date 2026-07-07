import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
import '../repositories/task_repository.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/add_task_sheet.dart';
import '../app_theme.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final TaskRepository _taskRepo = TaskRepository();
  bool _hasInitializedTasks = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedTasks) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.appUser != null) {
        context.read<TaskProvider>().listenToTasks(
              isAdmin: userProvider.appUser!.isAdmin,
              userEmail: userProvider.appUser!.email,
            );
        _hasInitializedTasks = true;
      }
    }
  }

  void _showAddTaskBottomSheet(AppUser currentUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withAlpha(180),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab(AppUser currentUser) {
    final taskProvider = context.watch<TaskProvider>();

    final filteredTasks = taskProvider.filtered(
      status: _selectedFilter,
      query: _searchQuery,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Greeting header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()} 👋',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.pending,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentUser.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Avatar
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              currentUser.name.isNotEmpty
                                  ? currentUser.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Summary cards
                    Row(
                      children: [
                        _buildSummaryCard(
                          label: 'Total',
                          count: taskProvider.totalCount,
                          icon: Icons.assignment_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                          label: 'Pending',
                          count: taskProvider.pendingCount,
                          icon: Icons.schedule_rounded,
                          color: AppColors.pending,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                          label: 'Active',
                          count: taskProvider.inProgressCount,
                          icon: Icons.bolt_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                          label: 'Done',
                          count: taskProvider.completedCount,
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 20),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all', taskProvider.totalCount),
                          const SizedBox(width: 8),
                          _buildFilterChip('Pending', 'pending', taskProvider.pendingCount),
                          const SizedBox(width: 8),
                          _buildFilterChip('In Progress', 'in progress', taskProvider.inProgressCount),
                          const SizedBox(width: 8),
                          _buildFilterChip('Completed', 'completed', taskProvider.completedCount),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // Sort row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${filteredTasks.length} task${filteredTasks.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (v) => context.read<TaskProvider>().setSortBy(v),
                    icon: const Icon(Icons.sort_rounded, size: 20),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'createdAt', child: Text('Date Created')),
                      const PopupMenuItem(value: 'dueDate', child: Text('Due Date')),
                      const PopupMenuItem(value: 'priority', child: Text('Priority')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Task list
          if (taskProvider.isLoading)
            const SliverFillRemaining(child: LoadingShimmer())
          else if (taskProvider.error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text('Error: ${taskProvider.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.read<TaskProvider>().listenToTasks(
                              isAdmin: currentUser.isAdmin,
                              userEmail: currentUser.email,
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredTasks.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.assignment_outlined,
                title: _searchQuery.isNotEmpty ? 'No results found' : 'No tasks yet',
                description: _searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Tap the + button to create your first task!',
                onActionPressed: _searchQuery.isEmpty
                    ? () => _showAddTaskBottomSheet(currentUser)
                    : null,
                actionLabel: _searchQuery.isEmpty ? 'Create Task' : null,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = filteredTasks[index];
                  return TaskCard(
                    task: task,
                    index: index,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(task: task),
                        ),
                      );
                    },
                    onComplete: task.status != TaskStatus.completed
                        ? () async {
                            final updated = Task(
                              id: task.id,
                              title: task.title,
                              description: task.description,
                              status: TaskStatus.completed,
                              priority: task.priority,
                              assignedTo: task.assignedTo,
                              createdAt: task.createdAt,
                              updatedAt: DateTime.now(),
                              dueDate: task.dueDate,
                            );
                            await _taskRepo.updateTask(updated);
                          }
                        : null,
                    onDelete: () async {
                      await _taskRepo.deleteTask(task.id);
                    },
                  );
                },
                childCount: filteredTasks.length,
              ),
            ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskBottomSheet(currentUser),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withAlpha(50) : AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userProvider.error != null || userProvider.appUser == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                const SizedBox(height: 16),
                Text(
                  userProvider.error ?? 'Authentication error. Please sign in again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await context.read<UserProvider>().signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: const Text('Sign Out'),
                )
              ],
            ),
          ),
        ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        height: 65,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
