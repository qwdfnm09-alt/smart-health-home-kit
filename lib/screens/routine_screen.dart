import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../services/routine_engine.dart';
import '../models/routine_task.dart';
import '../l10n/app_localizations.dart';


class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final StorageService _storageService = StorageService();

  void _generateRoutine() {
    final user = _storageService.getUserProfile();
    final history = _storageService.getAllHealthData();

    if (user != null) {
      final newRoutine = RoutineEngine.generateRoutine(user, history);
      _storageService.saveDailyRoutine(newRoutine);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تحديث الروتين اليومي بنجاح! ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى إكمال الملف الشخصي أولاً ⚠️")),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'nutrition': return Icons.local_drink;
      case 'exercise': return Icons.directions_run;
      case 'monitoring': return Icons.monitor_heart;
      case 'mental health': return Icons.self_improvement;
      default: return Icons.task_alt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'nutrition': return Colors.blue;
      case 'exercise': return Colors.orange;
      case 'monitoring': return Colors.red;
      case 'mental health': return Colors.purple;
      default: return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.dailyroutine),
          bottom: const TabBar(
            tabs: [
              Tab(text: "الروتين الأساسي", icon: Icon(Icons.list_alt)),
              Tab(text: "روتين AI ✨", icon: Icon(Icons.auto_awesome)),
            ],
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generateRoutine,
              tooltip: "إعادة توليد الروتين",
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTasksList(isAI: false),
            _buildTasksList(isAI: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList({required bool isAI}) {
    return ValueListenableBuilder(
      valueListenable: _storageService.routineBox.listenable(),
      builder: (context, Box<RoutineTask> box, _) {
        final tasks = box.values
            .where((task) => isAI ? task.type == 'ai' : task.type != 'ai')
            .toList();

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAI ? Icons.auto_awesome_outlined : Icons.calendar_today_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                Text(
                  isAI ? "لا توجد مهام ذكية حالياً" : "لا يوجد روتين ليومك بعد",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (!isAI) ...[
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _generateRoutine,
                    child: const Text("توليد روتين اليوم"),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "اسأل الـ AI في الشات وسيقوم باقتراح مهام مخصصة تظهر هنا!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final categoryColor = isAI ? Colors.teal : _getCategoryColor(task.category);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: isAI ? Colors.teal.withValues(alpha: 0.05) : null,
              child: CheckboxListTile(
                value: task.isCompleted,
                activeColor: categoryColor,
                onChanged: (bool? value) async {
                  // تحديث المهمة في Hive
                  task.isCompleted = value ?? false;
                  await task.save();
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAI ? Icons.psychology_outlined : _getCategoryIcon(task.category),
                    color: categoryColor,
                  ),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.description),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(task.time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
