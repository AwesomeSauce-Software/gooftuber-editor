import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/parsing/github.dart';
import 'package:http/http.dart' as http;

const apiBase = "https://api.awesomesauce.software";

Future<String> getChangelog(String tag) async {
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
        return message;
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

enum ClientState { upToDate, outOfDate, error }

String? latestTagCache;

Future<String?> getLatestTag() async {
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
