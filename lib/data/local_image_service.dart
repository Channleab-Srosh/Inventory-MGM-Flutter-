import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalImageService {
  /// Copies a picked image into <app documents>/product_images/ and returns the new path.
  static Future<String> saveProductImage(File picked) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'product_images'));
    if (!await dir.exists()) await dir.create(recursive: true);

    final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}$ext';
    final saved = await picked.copy(p.join(dir.path, fileName));
    return saved.path;
  }

  static Future<void> delete(String? path) async {
    if (path == null || path.startsWith('http')) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}