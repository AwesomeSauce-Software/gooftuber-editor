

import 'package:flutter/material.dart';

void showSnackbar(context, String text) {
  double width = MediaQuery.of(context).size.width;
  if (width < 400) {
    width = 0;
  }
  ScaffoldMessenger.of(context).showSnackBar(
      // right aligned snackbar
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(left: width==0? 10 : width - 400 - 10, bottom: 10, right: 10),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
}

Future<bool> showConfirmDialog(BuildContext context, String title, String content) async {
  var answer = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('Confirm'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
  return answer ?? false;
}