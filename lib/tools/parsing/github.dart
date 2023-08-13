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