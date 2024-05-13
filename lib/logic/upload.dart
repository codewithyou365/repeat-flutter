import 'package:dio/dio.dart';

typedef UploadProgressCallback = void Function(int sent, int total);

Future<Response> upload(String url, String filePath, String fileName, {UploadProgressCallback? progressCallback}) async {
  var postData = FormData.fromMap({"file": await MultipartFile.fromFile(filePath, filename: fileName)});
  var option = Options(method: "POST", contentType: "multipart/form-data");
  var dio = Dio();
  return await dio.post(
    url,
    data: postData,
    options: option,
    onSendProgress: (int sent, int total) {
      if (progressCallback != null) {
        progressCallback(sent, total);
      }
    },
  );
}
