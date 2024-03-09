import 'dart:developer';
import 'dart:io' show HttpClient, File, Directory;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert' show utf8;

import 'model/cache_base_model.dart';

/// This service searches for a file in the cache from the given URL, and returns it if it exists.
///
/// If the file does not exist in the cache, it downloads it, saves it, and returns it.
///
/// This way, the existence of the file can be checked in the cache first, and downloaded if it is not there.
///
/// Separating the cache mechanism into a separate class improves the readability of the code.
///
/// E.g:
/// ```dart
/// final cacheService = CacheService();
///  final file = await cacheService.getOrDownloadFile('http://example.com/file.mp3', 'file.mp3');
///```

/// Turkish
/// Bu hizmet, verilen URL'den önbellekte bir dosya arar ve varsa döndürür.
///
/// Eğer dosya önbellekte mevcut değilse, indirir, kaydeder ve geri döndürür.
///
/// Bu şekilde, dosyanın varlığı önce önbellekte kontrol edilebilir ve orada değilse indirilebilir.
///
/// Önbellek mekanizmasını ayrı bir sınıfa ayırmak kodun okunabilirliğini artırır.
///
/// Örn:
/// ```dart
/// final cacheService = CacheService();
/// final dosya = await cacheService.getOrDownloadFile('http://example.com/file.mp3', 'dosya.mp3');
///```

class CacheService {
  static final CacheService _singleton = CacheService._internal();

  factory CacheService() => _singleton;

  CacheService._internal();

  final String _folderName = "cached_files";

  /// This method is getting a file from the cache.
  Future<File> getFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$_folderName/$fileName';
    final file = File(filePath);
    return file;
  }

  Future<CacheBaseModel> getOrDownloadFile<T>(String url, String fileName,
      [bool? cacheEnabled, bool? isFile]) async {
    try {
      final file = await getFile(fileName);

      if (await file.exists()) {
        return CacheBaseModel<T>(status: true, file: file as T);
      } else {
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(url));
        if (cacheEnabled == null || cacheEnabled) {
          final response = await request.close();
          final bytes = await consolidateHttpClientResponseBytes(response);
          await file.writeAsBytes(bytes);

          return CacheBaseModel<T>(status: true, file: file as T);
        } else {
          final response = await request.close();
          if (isFile == null || !isFile) {
            final body = await response.transform(utf8.decoder).join();

            return CacheBaseModel<T>(status: false, file: body as T);
          } else {
            final bytes = await consolidateHttpClientResponseBytes(response);
            await file.writeAsBytes(bytes);

            return CacheBaseModel<T>(status: true, file: file as T);
          }
        }
      }
    } catch (e) {
      log('[CacheService]  $e');
      rethrow;
    }
  }

  /// This method is checking if a file exists in the cache.
  Future<bool> isFileExist(String fileName) async {
    return await getFile(fileName).then((file) async => await file.exists());
  }

  /// This method is deleting a file from the cache.
  Future<void> deleteFile(String fileName) async {
    final file = await getFile(fileName);
    if (await file.exists()) await file.delete();
  }

  /// This method is deleting all files from the cache.
  Future<void> deleteAllFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final filesDirectory = Directory('${directory.path}/$_folderName');
    final files = filesDirectory.listSync();

    for (final file in files) {
      await file.delete();
    }
  }
}
