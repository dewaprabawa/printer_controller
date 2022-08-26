import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as prefix;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printer_controller/shared/printer_helper_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageHelper {
  static Future<File> resizeImage(File file,
      {String? fileName, int? preferredWidth}) async {
    prefix.Image image = (await prefix.decodeImage(file.readAsBytesSync()))!;
     prefix.Image resized =  prefix.copyResize(image, width: preferredWidth ?? 640);

    String path =
        '${await _getImageDir()}/${fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}.png'}';

    File resizedFile = File(path)..writeAsBytesSync(prefix.encodePng(resized));

    return resizedFile;
  }

  static Future<String> _getImageDir() async {
    Directory externalDir = await getApplicationDocumentsDirectory();
    String dirPath = join(externalDir.path, "majoo/images");

    return dirPath;
  }


  static Future<String> getImagePathFromAsset(String urlAsset) async {
    String filename = urlAsset.split("/").last;
    var bytes = await rootBundle.load(urlAsset);
    String dir = (await getApplicationDocumentsDirectory()).path;
    final data = bytes.buffer;
    File file = await File('$dir/$filename').writeAsBytes(
        data.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));

    return file.path;
  }

  static Future<String> getImagePathFromAssetResizedForBill(
      String urlAsset) async {
    String filename = urlAsset.split("/").last;
    var bytes = await rootBundle.load(urlAsset);
    String dir = (await getApplicationDocumentsDirectory()).path;
    final data = bytes.buffer;
    File file = await File('$dir/$filename').writeAsBytes(
        data.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    file = await resizeImage(file, preferredWidth: 100);

    return file.path;
  }

  static Future<String> getPathImageFromNetworkResizedForBill(
      String urlNetwork) async {
    String path = "";

    String filename = urlNetwork.split("/").last;
    String dir = (await getApplicationDocumentsDirectory()).path;

    try {
      Response<List<int>> req = await Dio().get<List<int>>(urlNetwork,
          options: Options(responseType: ResponseType.bytes));
      if (req.statusCode == 200) {
        File file = File('$dir/$filename');
        file = await file.writeAsBytes(req.data!);
        file = await resizeImage(file, preferredWidth: 150);
        path = await file.path;
      }
    } catch (e, stackTrace) {
      debugPrint("exception $e");
      debugPrint("stackTrace $e");
      path = "";
    }
    return path;
  }

  static Future<String> getPathImageLogoBill() async {
   var sharedPreferences = await SharedPreferences.getInstance();
    String? urlLogoBill = sharedPreferences
        .getString(PrinterHelperConstant.PREFS_USAHA_LOGO_CABANG_BILL);

//Buat testing jika belum pernah connect
//    await App()
//        .sharedPreferences.remove(ConstantHelper.PREF_TEMP_URL_LOGO_BILL);
//    await App()
//        .sharedPreferences.remove(ConstantHelper.PREF_TEMP_PATH_LOCAL_LOGO_BILL);

    String tempUrlLogoBill = (sharedPreferences
            .getString(PrinterHelperConstant.PREF_TEMP_URL_LOGO_BILL) ??
        "");

    String tempPathLocalLogoBill = (sharedPreferences
            .getString(PrinterHelperConstant.PREF_TEMP_PATH_LOCAL_LOGO_BILL) ??
        "");

    String pathnya = "";

    if (urlLogoBill != "" && urlLogoBill != "null" && urlLogoBill != null) {
      print("urlLogoBill=" + urlLogoBill);
      if (urlLogoBill == tempUrlLogoBill) {
        print("urlLogoBill masih sama");
        pathnya = tempPathLocalLogoBill;
      } else {
        tempUrlLogoBill = urlLogoBill;
        pathnya = await getPathImageFromNetworkResizedForBill(urlLogoBill);
        tempPathLocalLogoBill = pathnya;
        if (pathnya != "") {
          print("new_tempUrlLogoBill=" + tempUrlLogoBill);
          await sharedPreferences.setString(
              PrinterHelperConstant.PREF_TEMP_URL_LOGO_BILL, tempUrlLogoBill);

          print("new_tempPathLocalLogoBill=" + tempPathLocalLogoBill);
          await sharedPreferences.setString(
              PrinterHelperConstant.PREF_TEMP_PATH_LOCAL_LOGO_BILL,
              tempPathLocalLogoBill);
        } else {
          pathnya = await getImagePathFromAssetResizedForBill(
              "assets/images/majoo_logo_print.jpg");
        }
      }
    } else {
      pathnya = await getImagePathFromAssetResizedForBill(
          "assets/images/majoo_logo_print.jpg");
    }

    return pathnya;
  }
}
