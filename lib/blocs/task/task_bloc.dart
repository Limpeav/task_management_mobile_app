import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../services/task_service.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskService _taskService;

  TaskBloc(this._taskService) : super(const TaskState()) {
    on<LoadTasksRequested>(_onLoadTasks);
    on<CreateTaskRequested>(_onCreateTask);
    on<UpdateTaskRequested>(_onUpdateTask);
    on<ToggleTaskCompletionRequested>(_onToggleCompletion);
    on<DeleteTaskRequested>(_onDeleteTask);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<StatusFilterChanged>(_onStatusFilterChanged);
    on<CategoryFilterChanged>(_onCategoryFilterChanged);
    on<PriorityFilterChanged>(_onPriorityFilterChanged);
    on<ClearFiltersRequested>(_onClearFilters);
  }

  Future<void> _onLoadTasks(
    LoadTasksRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final tasks = await _taskService.getTasks(event.userId);
      emit(state.copyWith(tasks: tasks, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load tasks: $e',
      ));
    }
  }

  Future<void> _onCreateTask(
    CreateTaskRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final newTask = await _taskService.createTask(
        userId: event.userId,
        title: event.title,
        description: event.description,
        priority: event.priority,
        category: event.category,
        dueDate: event.dueDate,
      );
      final updatedList = [newTask, ...state.tasks];
      emit(state.copyWith(
        tasks: updatedList,
        isLoading: false,
        successMessage: 'Task created successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create task: $e',
      ));
    }
  }

  Future<void> _onUpdateTask(
    UpdateTaskRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final updated = await _taskService.updateTask(event.task);
      final updatedList = state.tasks.map((t) {
        return t.id == updated.id ? updated : t;
      }).toList();
      emit(state.copyWith(
        tasks: updatedList,
        successMessage: 'Task updated!',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update task: $e'));
    }
  }

  Future<void> _onToggleCompletion(
    ToggleTaskCompletionRequested event,
    Emitter<TaskState> emit,
  ) async {
    // Optimistic UI update
    final toggled = event.task.copyWith(isCompleted: !event.task.isCompleted);
    final optimisticList = state.tasks.map((t) {
      return t.id == toggled.id ? toggled : t;
    }).toList();
    emit(state.copyWith(tasks: optimisticList));

    try {
      await _taskService.toggleTaskCompletion(event.task);
    } catch (e) {
      // Revert on error
      final revertedList = state.tasks.map((t) {
        return t.id == event.task.id ? event.task : t;
      }).toList();
      emit(state.copyWith(
        tasks: revertedList,
        errorMessage: 'Failed to update task status.',
      ));
    }
  }

  Future<void> _onDeleteTask(
    DeleteTaskRequested event,
    Emitter<TaskState> emit,
  ) async {
    final originalList = state.tasks;
    final updatedList = originalList.where((t) => t.id != event.taskId).toList();
    emit(state.copyWith(tasks: updatedList, successMessage: 'Task deleted'));

    try {
      await _taskService.deleteTask(event.userId, event.taskId);
    } catch (e) {
      // Revert on failure
      emit(state.copyWith(
        tasks: originalList,
        errorMessage: 'Failed to delete task: $e',
      ));
    }
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<TaskState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onStatusFilterChanged(
    StatusFilterChanged event,
    Emitter<TaskState> emit,
  ) {
    emit(state.copyWith(statusFilter: event.filter));
  }

  void _onCategoryFilterChanged(
    CategoryFilterChanged event,
    Emitter<TaskState> emit,
  ) {
    if (event.category == null || state.selectedCategory == event.category) {
      emit(state.copyWith(clearCategory: true));
    } else {
      emit(state.copyWith(selectedCategory: event.category));
    }
  }

  void _onPriorityFilterChanged(
    PriorityFilterChanged event,
    Emitter<TaskState> emit,
  ) {
    if (event.priority == null || state.selectedPriority == event.priority) {
      emit(state.copyWith(clearPriority: true));
    } else {
      emit(state.copyWith(selectedPriority: event.priority));
    }
  }

  void _onClearFilters(
    ClearFiltersRequested event,
    Emitter<TaskState> emit,
  ) {
    emit(state.copyWith(
      searchQuery: '',
      statusFilter: TaskStatusFilter.all,
      clearCategory: true,
      clearPriority: true,
    ));
  }
}
