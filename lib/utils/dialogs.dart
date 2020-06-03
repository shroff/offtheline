library dialogs;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<Uri> showUriDialog(
  BuildContext context,
  String title,
  Uri preset,
  bool allowHttp,
) {
  final controller = TextEditingController();
  var https = true;
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
                  preset = Uri.tryParse((https ? "https://" : "http://") + controller.text);
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
                        https = checked;
                        preset = Uri.tryParse((https ? "https://" : "http://") + controller.text);
                      });
                    },
                  ),
                  Text('HTTPS')
                ],
              )
          ],
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('CANCEL'),
            onPressed: () {
              Navigator.of(context).pop(null);
            },
          ),
          FlatButton(
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

Future<T> showProgressDialog<T>(BuildContext context, {String title, String message}) {
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

Future<bool> showAlertDialog(
  BuildContext context, {
  String title,
  String message,
  String negativeText,
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
          FlatButton(
            child: Text(negativeText),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        if (positiveText != null)
          FlatButton(
            child: Text(positiveText),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
      ],
    ),
  );
}

Future<String> showInputDialog(
  BuildContext context, {
  String title,
  String labelText,
  String hintText,
  String preset,
  bool numeric = false,
}) {
  TextEditingController controller = new TextEditingController()..text = preset;
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
        inputFormatters: numeric ? [WhitelistingTextInputFormatter(RegExp('\\d'))] : null,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
        FlatButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(controller.text);
          },
        )
      ],
    ),
  );
}
