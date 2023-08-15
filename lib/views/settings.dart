import 'package:flutter/material.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/apitools.dart';
import 'package:gooftuber_editor/tools/jsonexport.dart';
import 'package:gooftuber_editor/views/dialogs.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class Setting {
  String title;
  String subtitle;
  Widget trailing;
  List<SettingAction>? items;
  Setting(this.title, this.subtitle, this.trailing, {this.items});
}

class SettingAction {
  String title;
  Function() action;
  SettingAction(this.title, this.action);
}

class _SettingsViewState extends State<SettingsView> {
  Widget settingsGroup(String title, List<Widget> children) {
    var expanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          child: Column(
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(8),
                title:
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                trailing:
                    Icon(expanded ? Icons.expand_less : Icons.expand_more),
                onTap: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                firstChild: Container(),
                secondChild: Column(
                  children: [
                    const Divider(),
                    ...children,
                    const SizedBox(height: 8),
                  ],
                ), // Shown when expanded
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget settingsTile(Setting setting) {
    return (setting.items != null)
        ? PopupMenuButton(
            tooltip: '',
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              title: Text(setting.title),
              subtitle: Text(setting.subtitle),
              trailing: setting.trailing,
            ),
            itemBuilder: (context) {
              return [
                for (var i = 0; i < setting.items!.length; i++)
                  PopupMenuItem(
                    value: i,
                    child: Text(setting.items![i].title),
                  )
              ];
            },
            onSelected: (value) {
              setting.items![value].action();
            },
          )
        : ListTile(
            title: Text(setting.title),
            subtitle: Text(setting.subtitle),
            trailing: setting.trailing,
          );
  }

  Widget settingsTileTap(Setting setting) {
    return ListTile(
      shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
      title: Text(setting.title),
      subtitle: Text(setting.subtitle),
      trailing: setting.trailing,
      onTap: (setting.items?.length == 1)
          ? () {
              setting.items![0].action();
            }
          : null,
    );
  }

  var themes = ["Light", "Dark", "System"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            children: [
              settingsGroup("General", [
                ValueListenableBuilder(
                    valueListenable: appTheme,
                    builder: (context, theme, _) {
                      return settingsTile(Setting(
                        "Theme",
                        themes[theme],
                        const Icon(Icons.brightness_4_rounded),
                        items: [
                          for (var i = 0; i < themes.length; i++)
                            SettingAction(themes[i], () async {
                              appTheme.value = i;
                              await saveSettings();
                            })
                        ],
                      ));
                    }),
              ]),
              settingsGroup("Global Settings", [
                ValueListenableBuilder(
                    valueListenable: autoSave,
                    builder: (context, saveValue, _) {
                      return settingsTile(Setting(
                        "Auto Save Projects every 5 minutes",
                        'Save your projects automatically every 5 minutes to prevent data loss.',
                        saveValue
                            ? const Icon(Icons.check)
                            : const Icon(Icons.close),
                        items: [
                          SettingAction("On", () async {
                            autoSave.value = true;
                            await saveSettings();
                          }),
                          SettingAction("Off", () async {
                            autoSave.value = false;
                            await saveSettings();
                          })
                        ],
                      ));
                    }),
              ]),
              settingsGroup("About this App", [
                settingsTileTap(Setting(
                    "Gooftuber Avatar Editor",
                    "An App, made with lotsa, by AwesomeSauce Software",
                    const SizedBox(),
                    items: [
                      SettingAction("Show About", () async {
                        aboutDialog(context);
                      }),
                    ])),
                settingsTileTap(Setting(
                  "Version $currentTag",
                  "Click to check for updates",
                  const SizedBox(),
                  items: [
                    SettingAction("Check for Updates", () async {
                      var state = await isClientOutOfDate();
                      if (context.mounted) {
                        switch (state) {
                          case ClientState.upToDate:
                            showSnackbar(context, "You are up to date!");
                            break;
                          case ClientState.outOfDate:
                            showUpdateDialog(context);
                            break;
                          case ClientState.error:
                            showSnackbar(context,
                                "An error occured while checking for updates.",
                                color: Colors.red);
                            break;
                        }
                      }
                    })
                  ],
                ))
              ])
            ],
          ),
        ),
      ),
    );
  }
}
