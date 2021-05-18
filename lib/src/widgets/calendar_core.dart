// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../shared/utils.dart';
import 'calendar_page.dart';

typedef _OnCalendarPageChanged = void Function(int pageIndex, DateTime focusedDay);

/// custom - required for onPointerDown listener
typedef OnStartRangeSelection = void Function(DateTime day);
/// custom - required for onPointerUp listener
typedef OnEndRangeSelection = void Function(DateTime day);
/// custom - required for onPointerMove listener
typedef OnPanUpdate = void Function(DateTime day);

class CalendarCore extends StatelessWidget {
  final DateTime? focusedDay;
  final DateTime firstDay;
  final DateTime lastDay;
  final CalendarFormat calendarFormat;
  final DayBuilder? dowBuilder;
  final FocusedDayBuilder dayBuilder;
  final bool sixWeekMonthsEnforced;
  final bool dowVisible;
  final Decoration? dowDecoration;
  final Decoration? rowDecoration;
  final double? dowHeight;
  final double? rowHeight;
  final BoxConstraints constraints;
  final int? previousIndex;
  final StartingDayOfWeek startingDayOfWeek;
  final PageController? pageController;
  final ScrollPhysics? scrollPhysics;
  final _OnCalendarPageChanged onPageChanged;

  final OnStartRangeSelection onStartRangeSelection;
  final OnEndRangeSelection onEndRangeSelection;
  final OnPanUpdate onPanUpdate;

  final HashMap<DateTime, GlobalKey> keys = HashMap();

  CalendarCore({
    Key? key,
    this.dowBuilder,
    required this.dayBuilder,
    required this.onPageChanged,
    required this.firstDay,
    required this.lastDay,
    required this.constraints,
    this.dowHeight,
    this.rowHeight,
    this.startingDayOfWeek = StartingDayOfWeek.sunday,
    this.calendarFormat = CalendarFormat.month,
    this.pageController,
    this.focusedDay,
    this.previousIndex,
    this.sixWeekMonthsEnforced = false,
    this.dowVisible = true,
    this.dowDecoration,
    this.rowDecoration,
    this.scrollPhysics,
    required this.onStartRangeSelection,
    required this.onEndRangeSelection,
    required this.onPanUpdate
  })  : assert(!dowVisible || (dowHeight != null && dowBuilder != null)),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    keys.clear();

    return Listener(
        onPointerDown: (_) => _onStartRangeSelection(_),
        onPointerMove: (_) => _onPanUpdate(_),
        onPointerUp: (_) => _onEndRangeSelection(_),
        onPointerCancel: (_) => _onPointerCancel(_),
        child: PageView.builder(
          controller: pageController,
          physics: scrollPhysics,
          itemCount: _getPageCount(calendarFormat, firstDay, lastDay),
          itemBuilder: (context, index) {
            final baseDay = _getBaseDay(calendarFormat, index);
            final visibleRange = _getVisibleRange(calendarFormat, baseDay);
            final visibleDays = _daysInRange(visibleRange.start, visibleRange.end);

            final actualDowHeight = dowVisible ? dowHeight! : 0.0;
            final constrainedRowHeight = constraints.hasBoundedHeight
                ? (constraints.maxHeight - actualDowHeight) /
                    _getRowCount(calendarFormat, baseDay)
                : null;

            return CalendarPage(
              visibleDays: visibleDays,
              dowVisible: dowVisible,
              dowDecoration: dowDecoration,
              rowDecoration: rowDecoration,
              dowBuilder: (context, day) {
                return SizedBox(
                  height: dowHeight,
                  child: dowBuilder?.call(context, day),
                );
              },
              dayBuilder: (context, day) {
                DateTime baseDay;
                final previousFocusedDay = focusedDay;
                if (previousFocusedDay == null || previousIndex == null) {
                  baseDay = _getBaseDay(calendarFormat, index);
                } else {
                  baseDay =
                      _getFocusedDay(calendarFormat, previousFocusedDay, index);
                }

                GlobalKey k = GlobalKey();
                keys[day] = k;
                return SizedBox(
                  key: k,
                  height: constrainedRowHeight ?? rowHeight,
                  child: dayBuilder(context, day, baseDay),
                );
              },
            );
          },
          onPageChanged: (index) {
            DateTime baseDay;
            final previousFocusedDay = focusedDay;
            if (previousFocusedDay == null || previousIndex == null) {
              baseDay = _getBaseDay(calendarFormat, index);
            } else {
              baseDay = _getFocusedDay(calendarFormat, previousFocusedDay, index);
            }

            return onPageChanged(index, baseDay);
          },
        )
    );
  }

  void _onStartRangeSelection(PointerDownEvent evt) {
    _hitCell('_onStartRangeSelection', evt);
  }

  void _onEndRangeSelection(PointerUpEvent evt) {
    _hitCell('_onEndRangeSelection', evt);
  }

  void _onPanUpdate(PointerMoveEvent evt) {
    _hitCell('_onPanUpdate', evt);
  }

  void _onPointerCancel(PointerCancelEvent evt) {
    _hitCell('_onPointerCancel', evt);
  }

  void _hitCell(String info, PointerEvent evt) {
    bool found = false;
    keys.forEach((key, value) {
      RenderObject? box = value.currentContext!.findRenderObject();
      if (box is RenderBox) {
        if (box.hitTest(BoxHitTestResult(), position: box.globalToLocal(evt.position))) {
          //print(info + ' '  + key.toString());
          found = true;

          if (info == "_onStartRangeSelection") {
              onStartRangeSelection(key);
          }
          else if (info == "_onEndRangeSelection") {
              onEndRangeSelection(key);
          }
          else if (info == "_onPanUpdate") {
              onPanUpdate(key);
          }
        }
      }
    });

    if (!found)
      print('No hit test');
  }

  int _getPageCount(CalendarFormat format, DateTime first, DateTime last) {
    switch (format) {
      case CalendarFormat.month:
        return _getMonthCount(first, last) + 1;
      case CalendarFormat.twoWeeks:
        return _getTwoWeekCount(first, last) + 1;
      case CalendarFormat.week:
        return _getWeekCount(first, last) + 1;
      default:
        return _getMonthCount(first, last) + 1;
    }
  }

  int _getMonthCount(DateTime first, DateTime last) {
    final yearDif = last.year - first.year;
    final monthDif = last.month - first.month;

    return yearDif * 12 + monthDif;
  }

  int _getWeekCount(DateTime first, DateTime last) {
    return last.difference(_firstDayOfWeek(first)).inDays ~/ 7;
  }

  int _getTwoWeekCount(DateTime first, DateTime last) {
    return last.difference(_firstDayOfWeek(first)).inDays ~/ 14;
  }

  DateTime _getFocusedDay(
      CalendarFormat format, DateTime prevFocusedDay, int pageIndex) {
    if (pageIndex == previousIndex) {
      return prevFocusedDay;
    }

    final pageDif = pageIndex - previousIndex!;
    DateTime day;

    switch (format) {
      case CalendarFormat.month:
        day = DateTime.utc(prevFocusedDay.year, prevFocusedDay.month + pageDif);
        break;
      case CalendarFormat.twoWeeks:
        day = DateTime.utc(prevFocusedDay.year, prevFocusedDay.month,
            prevFocusedDay.day + pageDif * 14);
        break;
      case CalendarFormat.week:
        day = DateTime.utc(prevFocusedDay.year, prevFocusedDay.month,
            prevFocusedDay.day + pageDif * 7);
        break;
    }

    if (day.isBefore(firstDay)) {
      day = firstDay;
    } else if (day.isAfter(lastDay)) {
      day = lastDay;
    }

    return day;
  }

  DateTime _getBaseDay(CalendarFormat format, int pageIndex) {
    DateTime day;

    switch (format) {
      case CalendarFormat.month:
        day = DateTime.utc(firstDay.year, firstDay.month + pageIndex);
        break;
      case CalendarFormat.twoWeeks:
        day = DateTime.utc(
            firstDay.year, firstDay.month, firstDay.day + pageIndex * 14);
        break;
      case CalendarFormat.week:
        day = DateTime.utc(
            firstDay.year, firstDay.month, firstDay.day + pageIndex * 7);
        break;
    }

    if (day.isBefore(firstDay)) {
      day = firstDay;
    } else if (day.isAfter(lastDay)) {
      day = lastDay;
    }

    return day;
  }

  DateTimeRange _getVisibleRange(CalendarFormat format, DateTime focusedDay) {
    switch (format) {
      case CalendarFormat.month:
        return _daysInMonth(focusedDay);
      case CalendarFormat.twoWeeks:
        return _daysInTwoWeeks(focusedDay);
      case CalendarFormat.week:
        return _daysInWeek(focusedDay);
      default:
        return _daysInMonth(focusedDay);
    }
  }

  DateTimeRange _daysInWeek(DateTime focusedDay) {
    final daysBefore = _getDaysBefore(focusedDay);
    final firstToDisplay = focusedDay.subtract(Duration(days: daysBefore));
    final lastToDisplay = firstToDisplay.add(const Duration(days: 7));
    return DateTimeRange(start: firstToDisplay, end: lastToDisplay);
  }

  DateTimeRange _daysInTwoWeeks(DateTime focusedDay) {
    final daysBefore = _getDaysBefore(focusedDay);
    final firstToDisplay = focusedDay.subtract(Duration(days: daysBefore));
    final lastToDisplay = firstToDisplay.add(const Duration(days: 14));
    return DateTimeRange(start: firstToDisplay, end: lastToDisplay);
  }

  DateTimeRange _daysInMonth(DateTime focusedDay) {
    final first = _firstDayOfMonth(focusedDay);
    final daysBefore = _getDaysBefore(first);
    final firstToDisplay = first.subtract(Duration(days: daysBefore));

    if (sixWeekMonthsEnforced) {
      final end = firstToDisplay.add(const Duration(days: 42));
      return DateTimeRange(start: firstToDisplay, end: end);
    }

    final last = _lastDayOfMonth(focusedDay);
    final daysAfter = _getDaysAfter(last);
    final lastToDisplay = last.add(Duration(days: daysAfter));

    return DateTimeRange(start: firstToDisplay, end: lastToDisplay);
  }

  List<DateTime> _daysInRange(DateTime first, DateTime last) {
    final dayCount = last.difference(first).inDays + 1;
    return List.generate(
      dayCount,
      (index) => DateTime.utc(first.year, first.month, first.day + index),
    );
  }

  DateTime _firstDayOfWeek(DateTime week) {
    final daysBefore = _getDaysBefore(week);
    return week.subtract(Duration(days: daysBefore));
  }

  DateTime _firstDayOfMonth(DateTime month) {
    return DateTime.utc(month.year, month.month, 1);
  }

  DateTime _lastDayOfMonth(DateTime month) {
    final date = month.month < 12
        ? DateTime.utc(month.year, month.month + 1, 1)
        : DateTime.utc(month.year + 1, 1, 1);
    return date.subtract(const Duration(days: 1));
  }

  int _getRowCount(CalendarFormat format, DateTime focusedDay) {
    if (format == CalendarFormat.twoWeeks) {
      return 2;
    } else if (format == CalendarFormat.week) {
      return 1;
    } else if (sixWeekMonthsEnforced) {
      return 6;
    }

    final first = _firstDayOfMonth(focusedDay);
    final daysBefore = _getDaysBefore(first);
    final firstToDisplay = first.subtract(Duration(days: daysBefore));

    final last = _lastDayOfMonth(focusedDay);
    final daysAfter = _getDaysAfter(last);
    final lastToDisplay = last.add(Duration(days: daysAfter));

    return (lastToDisplay.difference(firstToDisplay).inDays + 1) ~/ 7;
  }

  int _getDaysBefore(DateTime firstDay) {
    return (firstDay.weekday + 7 - getWeekdayNumber(startingDayOfWeek)) % 7;
  }

  int _getDaysAfter(DateTime lastDay) {
    int invertedStartingWeekday = 8 - getWeekdayNumber(startingDayOfWeek);

    int daysAfter = 7 - ((lastDay.weekday + invertedStartingWeekday) % 7);
    if (daysAfter == 7) {
      daysAfter = 0;
    }

    return daysAfter;
  }
}
