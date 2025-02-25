import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

typedef CalendarOnDayTap = void Function(DateTime day);
typedef CalendarGetDayDescribe = String Function(DateTime day);
typedef CalendarOnPageChanged = void Function(DateTime focusedDay);

class CalendarWidget {
  static Widget buildTableCalendar(
    DateTime focusedDay, {
    CalendarOnPageChanged? onPageChanged,
    CalendarOnDayTap? onDayTap,
    CalendarGetDayDescribe? getDayDescribe,
  }) {
    var now = DateTime.now();
    return TableCalendar(
      firstDay: DateTime.utc(2024, 9, 1),
      lastDay: now.add(const Duration(days: 365)),
      focusedDay: focusedDay,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleTextFormatter: (date, _) => '${date.month}/${date.year}',
      ),
      onPageChanged: onPageChanged,
      calendarBuilders: CalendarBuilders(
        outsideBuilder: _dayBuilder(onDayTap: onDayTap, getDayDescribe: getDayDescribe),
        todayBuilder: _dayBuilder(onDayTap: onDayTap, getDayDescribe: getDayDescribe),
        defaultBuilder: _dayBuilder(onDayTap: onDayTap, getDayDescribe: getDayDescribe),
      ),
    );
  }

  static FocusedDayBuilder? _dayBuilder({
    CalendarOnDayTap? onDayTap,
    CalendarGetDayDescribe? getDayDescribe,
  }) {
    return (context, day, focusedDay) {
      String text = '';
      if (getDayDescribe != null) {
        text = getDayDescribe(day);
      }

      return Center(
        child: InkWell(
          onTap: () {
            onDayTap?.call(day);
          },
          child: Column(
            children: [
              day.year == DateTime.now().year && day.month == DateTime.now().month && day.day == DateTime.now().day
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: _renderDay(day, focusedDay),
                    )
                  : _renderDay(day, focusedDay),
              if (text.isNotEmpty)
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      );
    };
  }

  static Widget _renderDay(DateTime day, DateTime focusedDay) {
    return Center(
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: day.month == focusedDay.month ? Theme.of(Get.context!).colorScheme.onSurface : Theme.of(Get.context!).colorScheme.inversePrimary,
        ),
      ),
    );
  }
}
