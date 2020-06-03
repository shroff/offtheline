import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
const Duration _oneDay = Duration(days: 1);

class DatePickerRow extends StatefulWidget {
  final Function(DateTime) onDateChanged;
  final double buttonSpacing;
  final double iconSize;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String titleText;
  final TextStyle titleTextStyle;

  DatePickerRow({
    Key key,
    @required this.firstDate,
    @required this.lastDate,
    this.selectedDate,
    this.onDateChanged,
    this.buttonSpacing = 16.0,
    this.iconSize = 16.0,
    this.titleText,
    this.titleTextStyle = const TextStyle(fontSize: 14),
  })  : assert(firstDate != null),
        assert(lastDate != null),
        super(key: key);

  @override
  State<DatePickerRow> createState() => DatePickerRowState();
}

class DatePickerRowState extends State<DatePickerRow> {
  DateTime selectedDate;

  @override
  void initState() {
    selectedDate = widget.selectedDate ?? DateTime.now();
    super.initState();
  }

  void _setSelectedDate(DateTime date) {
    if (mounted)
      setState(() {
        selectedDate = date;
      });
    widget?.onDateChanged?.call(date);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.titleText != null)
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  widget.titleText,
                  style: widget.titleTextStyle,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  iconSize: widget.iconSize,
                  onPressed: selectedDate.difference(widget.firstDate).inDays <= 0
                      ? null
                      : () {
                          _setSelectedDate(selectedDate.subtract(_oneDay));
                        },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.buttonSpacing),
                  child: FlatButton(
                    child: Text(_dateFormat.format(selectedDate)),
                    onPressed: () async {
                      DateTime date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate.compareTo(widget.lastDate) > 0
                            ? widget.lastDate
                            : selectedDate.compareTo(widget.firstDate) < 0 ? widget.firstDate : selectedDate,
                        firstDate: widget.firstDate,
                        lastDate: widget.lastDate,
                      );
                      if (date != null) {
                        _setSelectedDate(date);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  iconSize: widget.iconSize,
                  onPressed: widget.lastDate.difference(selectedDate).inDays <= 0
                      ? null
                      : () {
                          _setSelectedDate(selectedDate.add(_oneDay));
                        },
                ),
              ],
            ),
          ],
        ),
      );
}
