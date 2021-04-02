library dialogs;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<Uri?> showUriDialog(
  BuildContext context, {
  String? title,
  Uri? preset,
  bool allowHttp = false,
}) {
  final controller = TextEditingController();
  bool https = true;
  if (preset != null) {
    controller.text = preset.authority + preset.path;
    if (allowHttp && preset.scheme == 'http') {
      https = false;
    }
  }
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: (title == null) ? null : Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: 'Address',
                hintText: 'api.example.com:8080/api',
              ),
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              onChanged: (value) {
                setState(() {
                  preset = Uri.tryParse(
                      (https ? "https://" : "http://") + controller.text);
                });
              },
            ),
            if (allowHttp)
              Row(
                children: <Widget>[
                  Checkbox(
                    value: https,
                    onChanged: (checked) {
                      setState(() {
                        https = checked!;
                        preset = Uri.tryParse(
                            (https ? "https://" : "http://") + controller.text);
                      });
                    },
                  ),
                  Text('HTTPS')
                ],
              )
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('CANCEL'),
            onPressed: () {
              Navigator.of(context).pop(null);
            },
          ),
          ElevatedButton(
            child: Text('OK'),
            onPressed: preset == null
                ? null
                : () {
                    Navigator.of(context).pop(preset);
                  },
          )
        ],
      ),
    ),
  );
}

Future showProgressDialog(
  BuildContext context, {
  String? title,
  String? message,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: (title == null) ? null : Text(title),
      content: Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircularProgressIndicator(),
          ),
          if (message != null)
            Text(
              message,
              softWrap: true,
              overflow: TextOverflow.fade,
            ),
        ],
      ),
    ),
  );
}

Future<bool?> showAlertDialog(
  BuildContext context, {
  String? title,
  String? message,
  String? negativeText,
  String positiveText = 'OK',
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: (title == null) ? null : Text(title),
      content: (message == null)
          ? null
          : Text(
              message,
              softWrap: true,
            ),
      actions: <Widget>[
        if (negativeText != null)
          TextButton(
            child: Text(negativeText),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ElevatedButton(
          child: Text(positiveText),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    ),
  );
}

Future<String?> showInputDialog(
  BuildContext context, {
  String? title,
  String? labelText,
  String? hintText,
  String? preset,
  TextCapitalization? capitalization,
  bool numeric = false,
  bool decimal = false,
}) {
  TextEditingController controller = new TextEditingController()
    ..text = (preset ?? '');
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: (title == null) ? null : Text(title),
      content: TextField(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
        ),
        autofocus: true,
        controller: controller,
        textCapitalization: capitalization ?? TextCapitalization.none,
        keyboardType: numeric
            ? TextInputType.numberWithOptions(decimal: decimal)
            : TextInputType.text,
      ),
      actions: <Widget>[
        TextButton(
          child: Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
        ElevatedButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(controller.text);
          },
        )
      ],
    ),
  );
}

Future<T?> showOptionsDialog<T>(
  BuildContext context,
  List<T> options,
  Widget Function(T) buildItem, {
  String? titleText,
  bool Function(T, String)? filter,
}) async {
  var results = options;
  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        scrollable: true,
        title: (titleText == null) ? null : Text(titleText),
        content: results.length == 0
            ? Center(child: Text('No results'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (filter != null)
                    TextField(
                      decoration:
                          InputDecoration(hintText: 'Type to filter...'),
                      onChanged: (value) {
                        final query = value.toLowerCase();
                        final filtered = options
                            .where((element) => filter(element, query))
                            .toList();
                        setState(() {
                          results = filtered;
                        });
                      },
                    ),
                  for (final option in results) buildItem(option),
                ],
              ),
      ),
    ),
  );
}
