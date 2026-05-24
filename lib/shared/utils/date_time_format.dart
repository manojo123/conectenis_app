import 'package:flutter/material.dart';

DateTime roundToFiveMinutes(DateTime dateTime) {
  final roundedMinute = ((dateTime.minute + 2.5) ~/ 5) * 5;
  if (roundedMinute >= 60) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour + 1,
      0,
    );
  }
  return DateTime(
    dateTime.year,
    dateTime.month,
    dateTime.day,
    dateTime.hour,
    roundedMinute,
  );
}

String formatDateTimePt(DateTime dt) {
  final local = dt.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

Future<DateTime?> pickDateTimeWithFiveMinuteSteps(
  BuildContext context, {
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (date == null || !context.mounted) return null;

  final rounded = roundToFiveMinutes(initial);
  final pickedTime = await showDialog<TimeOfDay>(
    context: context,
    builder: (ctx) => _FiveMinuteTimeDialog(
      initial: TimeOfDay(hour: rounded.hour, minute: rounded.minute),
    ),
  );
  if (pickedTime == null) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}

class _FiveMinuteTimeDialog extends StatefulWidget {
  const _FiveMinuteTimeDialog({required this.initial});

  final TimeOfDay initial;

  @override
  State<_FiveMinuteTimeDialog> createState() => _FiveMinuteTimeDialogState();
}

class _FiveMinuteTimeDialogState extends State<_FiveMinuteTimeDialog> {
  static const _minutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: widget.initial.hour);
    final closest = _minutes.reduce(
      (a, b) => (widget.initial.minute - a).abs() <= (widget.initial.minute - b).abs() ? a : b,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _minutes.indexOf(closest).clamp(0, _minutes.length - 1),
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Horário'),
      content: SizedBox(
        height: 160,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              child: ListWheelScrollView.useDelegate(
                controller: _hourController,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 24,
                  builder: (_, i) => Center(child: Text(i.toString().padLeft(2, '0'))),
                ),
              ),
            ),
            const Text(':', style: TextStyle(fontSize: 24)),
            SizedBox(
              width: 70,
              child: ListWheelScrollView.useDelegate(
                controller: _minuteController,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: _minutes.length,
                  builder: (_, i) => Center(
                    child: Text(_minutes[i].toString().padLeft(2, '0')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              TimeOfDay(
                hour: _hourController.selectedItem,
                minute: _minutes[_minuteController.selectedItem],
              ),
            );
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
