import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/parsing/github.dart';
import 'package:gooftuber_editor/tools/platformtools.dart';
import 'package:gooftuber_editor/views/dialogs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

const apiBase = "https://api.awesomesauce.software";

Future<String> getChangelog(String tag) async {
  if (disableOnlineFeatures.value) return "Online features disabled, to enable them go to settings.";
  if (tag == 'latest') {
    var latest = await getLatestTag();
    if (latest == null) {
      return 'Error getting Changelog!';
    } else {
      tag = latest;
    }
  }
  // get the tag sha from github
  const url =
      "https://api.github.com/repos/Awesomesauce-Software/gooftuber-editor/git/refs/tags";
  var tags = await http.get(Uri.parse(url));

  if (tags.statusCode == 200) {
    List<GitTags> gitTagsFromJson(String str) =>
        List<GitTags>.from(json.decode(str).map((x) => GitTags.fromJson(x)));
    List<GitTags> gitTags = gitTagsFromJson(tags.body);
    GitTags tagMatched = gitTags.firstWhere(
        (element) => element.ref == "refs/tags/$tag",
        orElse: () => GitTags(
            ref: "",
            nodeId: "",
            url: "",
            object: Object(sha: "", type: "", url: "")));
    String latestTag = tagMatched.object.sha;
    debugPrint(latestTag);
    // get the changelog from github
    var url =
        "https://api.github.com/repos/AwesomeSauce-Software/gooftuber-editor/git/tags/$latestTag";
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map<String, dynamic> gitTagFromJson(String str) =>
          Map<String, dynamic>.from(json.decode(str));
      Map<String, dynamic> gitTag = gitTagFromJson(response.body);
      var message = gitTag["message"];
      if (message.replaceAll("\n", "").replaceAll("\r", "") != "") {
        return message.replaceAll("\\n", "\n");
      } else {
        return "No changelog for this version";
      }
    } else {
      return "Error getting changelog";
    }
  } else {
    return "Error getting changelog";
  }
}

Future<Uint8List?> downloadFile(context, Function(int, int) onProgress) async {
  if (disableOnlineFeatures.value) return null;
  var platform = getPlatformString();
  if (platform == null || latestTagCache == null) {
    showSnackbar(context, "Error getting update",
        action: SnackBarAction(
            label: "Show on GitHub",
            onPressed: () {
              launchUrl(Uri.parse(
                  "https://github.com/AwesomeSauce-Software/gooftuber-editor/releases"));
            }));
    return null;
  }
  var url =
      "https://github.com/AwesomeSauce-Software/gooftuber-editor/releases/download/$latestTagCache/gooftuber-editor-$latestTagCache-$platform.zip";
  // download file with progress callback
  debugPrint(url);
  final dio = Dio(BaseOptions(
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
    },
  ));
  var response = await dio.get(
    url,
    onReceiveProgress: (received, total) {
      if (total != -1) {
        onProgress(received, total);
      }
    },
    options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) {
          return status! < 500;
        }),
  );
  if (response.statusCode == 200) {
    return response.data;
  } else {
    return null;
  }
}

enum ClientState { upToDate, outOfDate, error }

String? latestTagCache;

Future<String?> getLatestTag() async {
  if (disableOnlineFeatures.value) return null;
  // check if cached in latestTagCache
  if (latestTagCache != null) {
    return latestTagCache;
  }
  // get the tag sha from github
  const url =
      "https://api.github.com/repos/Awesomesauce-Software/gooftuber-editor/git/refs/tags";
  var tags = await http.get(Uri.parse(url));

  if (tags.statusCode == 200) {
    List<GitTags> gitTagsFromJson(String str) =>
        List<GitTags>.from(json.decode(str).map((x) => GitTags.fromJson(x)));
    List<GitTags> gitTags = gitTagsFromJson(tags.body);
    String latestTag = gitTags.last.ref.replaceAll("refs/tags/", "");
    latestTagCache = latestTag;
    return latestTag;
  } else {
    return null;
  }
}

Future<ClientState> isClientOutOfDate() async {
  if (disableOnlineFeatures.value) return ClientState.upToDate;
  // check if client is out of date by comparing version numbers with github tags
  String? latestTag = await getLatestTag();
  if (latestTag != null) {
    if (tagToVersion(latestTag) > tagToVersion(currentTag)) {
      return ClientState.outOfDate;
    } else {
      return ClientState.upToDate;
    }
  } else {
    return ClientState.error;
  }
}

int tagToVersion(String tag) {
  return int.parse(tag.replaceAll(".", "").replaceAll("v", ""));
}

Future<bool> isApiUp() {
  if (disableOnlineFeatures.value) return Future.value(false);
  // if apiBase/ping is status 200, return true

  return http.get(Uri.parse("$apiBase/ping")).then((response) {
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  });
}

Future<bool> submitAvatar(String json, String code) {
  if (disableOnlineFeatures.value) return Future.value(false);
  return http
      .post(Uri.parse("$apiBase/upload-own/$code"), body: json)
      .then((response) {
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  });
}
