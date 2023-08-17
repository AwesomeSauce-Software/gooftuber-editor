import 'package:flutter/material.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/apitools.dart';
import 'package:gooftuber_editor/tools/jsonexport.dart';
import 'package:gooftuber_editor/tools/platformtools.dart';
import 'package:gooftuber_editor/views/dialogs.dart';
import 'package:gooftuber_editor/views/editor.dart';
import 'package:gooftuber_editor/views/palette.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class Setting {
  String title;
  String subtitle;
  Widget? trailing;
  List<SettingAction>? items;
  Widget? leading;
  bool? state;
  Setting(this.title, this.subtitle, this.trailing,
      {this.items, this.leading, this.state});
}

class SettingAction {
  String title;
  Function() action;
  SettingAction(this.title, this.action);
}

class _SettingsViewState extends State<SettingsView> {
  Widget settingsGroup(String title, List<Widget> children, int expanded) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
          child: Card(
            child: Column(
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(8),
                  title: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
                    child: Icon(expandedStates[expanded]
                        ? Icons.expand_less
                        : Icons.expand_more),
                  ),
                  onTap: () {
                    setState(() {
                      expandedStates[expanded] = !expandedStates[expanded];
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
                  crossFadeState: expandedStates[expanded]
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget settingsTile(Setting setting) {
    return (setting.items != null) // if we have 2, we might as well toggle
        ? (setting.items!.length != 2)
            ? PopupMenuButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tooltip: '',
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  title: Text(setting.title),
                  subtitle: Text(setting.subtitle),
                  trailing: setting.trailing,
                  leading: setting.leading,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(setting.title),
                subtitle: Text(setting.subtitle),
                trailing: setting.trailing,
                leading: setting.leading,
                onTap: () {
                  if (setting.state ?? true) {
                    setting.items![1].action();
                  } else {
                    setting.items![0].action();
                  }
                },
              )
        : ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(setting.title),
            subtitle: Text(setting.subtitle),
            trailing: setting.trailing,
          );
  }

  Widget settingsSubGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        ...children,
      ],
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
      leading: setting.leading,
      onTap: (setting.items?.length == 1)
          ? () {
              setting.items![0].action();
            }
          : null,
    );
  }

  var themes = ["Light", "Dark", "System"];
  var themesIcon = [
    const Icon(Icons.brightness_7_rounded),
    const Icon(Icons.brightness_3_rounded),
    const Icon(Icons.brightness_auto_rounded)
  ];

  var expandedStates = [false, false];

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    var big = width > 716;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            children: [
              settingsGroup(
                  "General",
                  [
                    settingsSubGroup("Appearance", [
                      ValueListenableBuilder(
                          valueListenable: appTheme,
                          builder: (context, theme, _) {
                            return settingsTile(Setting(
                              "Theme",
                              themes[theme],
                              themesIcon[theme],
                              items: [
                                for (var i = 0; i < themes.length; i++)
                                  SettingAction(themes[i], () async {
                                    appTheme.value = i;
                                    await saveSettings();
                                  })
                              ],
                              leading: const Icon(Icons.brightness_4_rounded),
                            ));
                          }),
                      if (big)
                        ValueListenableBuilder(
                            valueListenable: familiarityMode,
                            builder: (context, value, _) {
                              return settingsTile(Setting(
                                "Familiarity Mode",
                                "Swap Drawer and Navigation Rail position",
                                Switch(
                                    value: value,
                                    onChanged: (value) async {
                                      familiarityMode.value = value;
                                      await saveSettings();
                                    }),
                                items: [
                                  SettingAction("On", () async {
                                    familiarityMode.value = true;
                                    await saveSettings();
                                  }),
                                  SettingAction("Off", () async {
                                    familiarityMode.value = false;
                                    await saveSettings();
                                  })
                                ],
                                leading: const Icon(Icons.brightness_4_rounded),
                                state: value,
                              ));
                            }),
                    ]),
                    const SizedBox(height: 16),
                    settingsSubGroup("Editor Settings", [
                      ValueListenableBuilder(
                          valueListenable: autoSave,
                          builder: (context, saveValue, _) {
                            return settingsTile(Setting(
                                'Auto Save Projects every 5 minutes',
                                'Save your projects automatically every 5 minutes to prevent data loss.',
                                Switch(
                                    value: saveValue,
                                    onChanged: (value) async {
                                      autoSave.value = value;
                                      await saveSettings();
                                    }),
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
                                leading: const Icon(Icons.save_rounded),
                                state: saveValue));
                          }),
                      ValueListenableBuilder(
                          valueListenable: previewsVisible,
                          builder: (context, previewsValue, _) {
                            return settingsTile(Setting(
                                'Show Previews',
                                'Show Previews in the Frames Drawer',
                                Switch(
                                    value: previewsValue,
                                    onChanged: (value) async {
                                      previewsVisible.value = value;
                                      await saveSettings();
                                    }),
                                items: [
                                  SettingAction("On", () async {
                                    previewsVisible.value = true;
                                    await saveSettings();
                                  }),
                                  SettingAction("Off", () async {
                                    previewsVisible.value = false;
                                    await saveSettings();
                                  })
                                ],
                                leading: const Icon(Icons.preview_rounded),
                                state: previewsValue));
                          }),
                      ValueListenableBuilder(
                          valueListenable: disableOnlineFeatures,
                          builder: (context, value, _) {
                            return settingsTile(Setting(
                                'Offline Mode',
                                'Disable all online features.',
                                Switch(
                                    value: value,
                                    onChanged: (value) async {
                                      disableOnlineFeatures.value = value;
                                      await saveSettings();
                                    }),
                                items: [
                                  SettingAction("On", () async {
                                    disableOnlineFeatures.value = true;
                                    showSnackbar(context,
                                        "Restart the App to apply the changes.");
                                    await saveSettings();
                                  }),
                                  SettingAction("Off", () async {
                                    disableOnlineFeatures.value = false;
                                    await saveSettings();
                                  })
                                ],
                                leading: const Icon(Icons.wifi_off_rounded),
                                state: value));
                          }),
                      settingsTileTap(Setting(
                          "Palettes",
                          "Edit, add or Export your Color-Palettes for the Editor",
                          const Icon(Icons.chevron_right_rounded),
                          items: [
                            SettingAction("Edit", () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PaletteEditor()),
                              );
                            }),
                          ],
                          leading: const Icon(Icons.palette_rounded))),
                    ]),
                  ],
                  0),
              settingsGroup(
                  "About this App",
                  [
                    settingsTileTap(Setting(
                        "Gooftuber Avatar Editor",
                        "An App, made with lotsa, by AwesomeSauce Software",
                        const Icon(Icons.chevron_right_rounded),
                        items: [
                          SettingAction("Show About", () async {
                            aboutDialog(context);
                          }),
                        ],
                        leading: const Icon(Icons.info_rounded))),
                    settingsTileTap(Setting(
                        "Need Help?",
                        "Click here to open the Documentation",
                        const Icon(Icons.open_in_browser_rounded),
                        items: [
                          SettingAction("Show Documentation", () async {
                            launchUrl(Uri.parse(
                                'https://docs.awesomesauce.software/gooftuber/editor/main.html'));
                          }),
                        ],
                        leading: const Icon(Icons.help_rounded))),
                    if (!isPlatformMobile()) settingsTileTap(Setting(
                      "Version $currentTag",
                      disableOnlineFeatures.value
                          ? "Cannot check for Updates - Offline Mode on."
                          : "Click to check for updates",
                      disableOnlineFeatures.value
                          ? null
                          : const Icon(Icons.chevron_right_rounded),
                      items: [
                        if (!disableOnlineFeatures.value)
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
                      leading: const Icon(Icons.update_rounded),
                    ))
                  ],
                  1)
            ],
          ),
        ),
      ),
    );
  }
}
