
import 'dart:convert';

import 'package:http/http.dart' as http;

const apiBase = "https://api.awesomesauce.software";

class GitTags {
    String ref;
    String nodeId;
    String url;
    Object object;

    GitTags({
        required this.ref,
        required this.nodeId,
        required this.url,
        required this.object,
    });

    factory GitTags.fromJson(Map<String, dynamic> json) => GitTags(
        ref: json["ref"],
        nodeId: json["node_id"],
        url: json["url"],
        object: Object.fromJson(json["object"]),
    );

    Map<String, dynamic> toJson() => {
        "ref": ref,
        "node_id": nodeId,
        "url": url,
        "object": object.toJson(),
    };
}

class Object {
    String sha;
    String type;
    String url;

    Object({
        required this.sha,
        required this.type,
        required this.url,
    });

    factory Object.fromJson(Map<String, dynamic> json) => Object(
        sha: json["sha"],
        type: json["type"],
        url: json["url"],
    );

    Map<String, dynamic> toJson() => {
        "sha": sha,
        "type": type,
        "url": url,
    };
}


Future<bool?> isClientOutOfDate() {
  // check if client is out of date by comparing version numbers with github tags

  const url = "https://api.github.com/repos/Awesomesauce-Software/gooftuber-editor/git/refs/tags";
  return http.get(Uri.parse(url)).then((response) {
    if (response.statusCode == 200) {
      List<GitTags> gitTagsFromJson(String str) => List<GitTags>.from(json.decode(str).map((x) => GitTags.fromJson(x)));
      List<GitTags> gitTags = gitTagsFromJson(response.body);
      String latestTag = gitTags.last.ref.replaceAll("refs/tags/", "");
      String currentTag = "v1.0.1";
      if (latestTag != currentTag) {
        return true;
      } else {
        return false;
      }
    } else {
      return null;
    }
  });
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
  return http.post(Uri.parse("$apiBase/upload-own/$code"), body: json).then((response) {
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  });
}