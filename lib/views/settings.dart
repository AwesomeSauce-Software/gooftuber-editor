import 'package:flutter/material.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/jsonexport.dart';

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
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget settingsTile(Setting setting) {
    return (setting.items != null)? PopupMenuButton(
      tooltip: '',
      child: ListTile(
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
    ) : ListTile(
      title: Text(setting.title),
      subtitle: Text(setting.subtitle),
      trailing: setting.trailing,
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
              ])
            ],
          ),
        ),
      ),
    );
  }
}
