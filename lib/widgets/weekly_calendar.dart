import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, int> mealCounts;

  const WeeklyCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.mealCounts = const {},
  });

  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  late DateTime _currentWeekStart;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(widget.selectedDate);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> _getWeekDays(DateTime weekStart) {
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _currentWeekStart = _getWeekStart(today);
    });
    widget.onDateSelected(today);
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays(_currentWeekStart);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with month/year and navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_currentWeekStart),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _goToPreviousWeek,
                    icon: const Icon(Icons.chevron_left),
                    iconSize: 28,
                  ),
                  TextButton(
                    onPressed: _goToToday,
                    child: const Text('Today'),
                  ),
                  IconButton(
                    onPressed: _goToNextWeek,
                    icon: const Icon(Icons.chevron_right),
                    iconSize: 28,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 8),

          // Calendar days
          SizedBox(
            height: 80,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                // Handle page changes if needed
              },
              itemBuilder: (context, pageIndex) {
                return Row(
                  children: weekDays.map((date) {
                    final dateKey = DateTime(date.year, date.month, date.day);
                    final isSelected = dateKey ==
                        DateTime(widget.selectedDate.year,
                            widget.selectedDate.month, widget.selectedDate.day);
                    final isToday = dateKey == today;
                    final mealCount = widget.mealCounts[dateKey] ?? 0;
                    final isCurrentMonth =
                        date.month == _currentWeekStart.month;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onDateSelected(date),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue
                                : isToday
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday && !isSelected
                                ? Border.all(color: Colors.blue, width: 1)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isCurrentMonth
                                          ? Colors.black87
                                          : Colors.grey[400],
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Meal count indicator
                              if (mealCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$mealCount',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 16,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Week summary
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeekStat('Days Planned',
                    _getPlannedDaysCount().toString(), Icons.calendar_today),
                _buildWeekStat('Total Meals', _getTotalMealsCount().toString(),
                    Icons.restaurant_menu),
                _buildWeekStat('Completion', '${_getCompletionPercentage()}%',
                    Icons.check_circle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  int _getPlannedDaysCount() {
    final weekDays = _getWeekDays(_currentWeekStart);
    return weekDays.where((date) {
      final dateKey = DateTime(date.year, date.month, date.day);
      return (widget.mealCounts[dateKey] ?? 0) > 0;
    }).length;
  }

  int _getTotalMealsCount() {
    final weekDays = _getWeekDays(_currentWeekStart);
    return weekDays.fold(0, (total, date) {
      final dateKey = DateTime(date.year, date.month, date.day);
      return total + (widget.mealCounts[dateKey] ?? 0);
    });
  }

  int _getCompletionPercentage() {
    final plannedDays = _getPlannedDaysCount();
    return ((plannedDays / 7) * 100).round();
  }
}
