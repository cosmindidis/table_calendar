// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../utils.dart';

class TableRangeExample extends StatefulWidget {
  @override
  _TableRangeExampleState createState() => _TableRangeExampleState();
}

class _TableRangeExampleState extends State<TableRangeExample> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOn; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? rangeStartDate;
  DateTime? rangeEndDate;

  DateTime currentDate = DateTime.now();
  DateTime firstDay = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime lastDay = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TableCalendar - Range'),
      ),
      body: TableCalendar(
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: _focusedDay,
        //selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        rangeStartDay: rangeStartDate,
        rangeEndDay: rangeEndDate,
        calendarFormat: _calendarFormat,
        rangeSelectionMode: _rangeSelectionMode,
        headerVisible: false,
        headerStyle: HeaderStyle(
          leftChevronVisible: false,
          rightChevronVisible: false,
          formatButtonVisible: false,
        ),
        // onDaySelected: (selectedDay, focusedDay) {
        //   if (!isSameDay(_selectedDay, selectedDay)) {
        //     setState(() {
        //       _selectedDay = selectedDay;
        //       _focusedDay = focusedDay;
        //       _rangeStart = null; // Important to clean those
        //       _rangeEnd = null;
        //       _rangeSelectionMode = RangeSelectionMode.toggledOff;
        //     });
        //   }
        // },
        onRangeSelected: (start, end, focusedDay, eventName) async {
          setState(() {
            rangeStartDate = start;
            rangeEndDate = end;
          });

          if (eventName == "onEndRangeSelection") {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  child: Container(
                    height: 50,
                    width: 50,
                    color: Colors.grey.shade200,
                    child: Center(child: Text("Test"),))
                );
            });
          }

          if (eventName == "onEndRangeSelection") {
            setState(() {
              rangeStartDate = null;
              rangeEndDate = null;
            });
        }
        },
        // onFormatChanged: (format) {
        //   if (_calendarFormat != format) {
        //     setState(() {
        //       _calendarFormat = format;
        //     });
        //   }
        // },
        // onPageChanged: (focusedDay) {
        //   _focusedDay = focusedDay;
        // },
      ),
    );
  }
}
