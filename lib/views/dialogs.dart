import 'package:flutter/material.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/apitools.dart';
import 'package:gooftuber_editor/tools/jsonexport.dart';
import 'package:gooftuber_editor/tools/platformtools.dart';
import 'package:gooftuber_editor/tools/webtools.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void aboutDialog(BuildContext context) {
  return showAboutDialog(
      context: context,
      applicationIcon: Image.asset('assets/icon.png', width: 48, height: 48),
      applicationName: 'Gooftuber Avatar Maker',
      applicationVersion: currentTag,
      children: [
        const Text('Made by AwesomeSauce Software',
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                tooltip: 'Changelog',
                onPressed: () {
                  Navigator.pop(context);
                  showChangelogDialog(context);
                },
                icon: const Icon(Icons.speaker_notes_rounded)),
            IconButton(
                tooltip: 'Source',
                onPressed: () => launchUrl(Uri.parse(
                    "https://github.com/AwesomeSauce-Software/gooftuber-editor")),
                icon: const Icon(Icons.code_rounded)),
          ],
        )
      ]);
}

void showSnackbar(context, String text,
    {Color? color, SnackBarAction? action}) {
  double width = MediaQuery.of(context).size.width;
  if (width < 400) {
    width = 0;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    // right aligned snackbar
    SnackBar(
      backgroundColor: color,
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.startToEnd,
      showCloseIcon: !isPlatformMobile(),
      margin: EdgeInsets.only(
          left: width == 0 ? 10 : width - 400 - 10, bottom: 10, right: 10),
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      action: action,
    ),
  );
}

Future<void> showChangelogDialog(BuildContext context) async {
  if (context.mounted) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('What\'s new?'),
          content: Builder(builder: (context) {
            return FutureBuilder(
              future: getChangelog(currentTag),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SingleChildScrollView(
                    child: Text(snapshot.data.toString()),
                  );
                } else {
                  return const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [CircularProgressIndicator()],
                  );
                }
              },
            );
          }),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

Future<bool?> showUpdateDialog(BuildContext context) async {
  var prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('updateDialog') ?? false) {
    return Future.value(false);
  }
  if (context.mounted) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('A new version is available! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Changes:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              FutureBuilder(
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data.toString());
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                  future: getChangelog('latest')),
              const Text('Do you want to download the new version of the app?'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                if (isPlatformWeb()) {
                  reloadPage();
                  Navigator.of(context).pop(true);
                  return;
                }
                if (context.mounted) Navigator.of(context).pop(true);
                var result = await downloadUpdateDialog(context);
                if (result != null && result) {
                  if (context.mounted) {
                    showDownloadDoneDialog(context);
                  }
                } else {
                  if (context.mounted) {
                    showSnackbar(context,
                          "Download failed, please check the GitHub releases page manually.",
                          action: SnackBarAction(
                              label: "Open",
                              onPressed: () => launchUrl(Uri.parse(
                                  "https://github.com/AwesomeSauce-Software/gooftuber-editor/releases"))));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  } else {
    return Future.value(false);
  }
}

Future<bool?> downloadUpdateDialog(
  context,
) async {
  if (context.mounted) {
    ValueNotifier<int> progress = ValueNotifier(0);
    var done = false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: progress.value == 100,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Downloading update, please wait...'),
          content: FutureBuilder(
              future: downloadFile(context, (received, total) {
                if (total != -1 && !done) {
                  progress.value = (received / total * 100).floor();
                }
              }),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var fileName = "gooftuber-editor-latest.zip";
                  if (snapshot.data != null && context.mounted) {
                    done = true;
                    exportBytes(context, snapshot.data!, fileName, ['zip']);
                    Navigator.of(context).pop(true);
                  } else {
                    if (context.mounted) {
                      Navigator.of(context).pop(false);
                    }
                  }
                  return const SizedBox();
                } else {
                  return ValueListenableBuilder(
                      valueListenable: progress,
                      builder: (context, progressNow, _) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(value: progressNow / 100),
                            const SizedBox(height: 16),
                            Text('$progressNow%'),
                          ],
                        );
                      });
                }
              }),
        );
      },
    );
  }
  return null;
}

Future<void> showDownloadDoneDialog(BuildContext context) async {
  if (context.mounted) {
    return showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download complete!'),
          content: const Text(
              'The download is complete, please install the app and delete the old one.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Exit'),
              onPressed: () {
                exitApp();
              },
            ),
          ],
        );
      },
    );
  }
}

Future<bool?> showDownloadDialog(BuildContext context, {force = false}) async {
  var prefs = await SharedPreferences.getInstance();
  if (!force && (prefs.getBool('downloadDialog') ?? false)) {
    return Future.value(false);
  }
  if (context.mounted) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('This App could be so much faster! 🚀'),
          content: const Text(
              'Do you want to download the desktop app for a better experience?'),
          actions: <Widget>[
            if (!force)
              TextButton(
                child: const Text('No, never ask again'),
                onPressed: () {
                  prefs.setBool('downloadDialog', true);
                  Navigator.of(context).pop(false);
                },
              ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                launchUrl(Uri.parse(
                    'https://github.com/AwesomeSauce-Software/gooftuber-editor/releases'));
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  } else {
    return Future.value(false);
  }
}

Future<bool> showConfirmDialog(
    BuildContext context, String title, String content) async {
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
