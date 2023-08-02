
import 'package:http/http.dart' as http;

const apiBase = "https://api.awesomesauce.software";

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