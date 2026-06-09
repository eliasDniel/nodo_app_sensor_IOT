import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/metadata_payload.dart';

class PendingStorageService {
  static const _folderName = 'centinela_pending';

  Future<Directory> _pendingDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, _folderName));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<void> save({
    required Uint8List wavBytes,
    required MetadataPayload meta,
  }) async {
    final dir = await _pendingDir();
    final base = p.join(dir.path, meta.eventoId);
    await File('$base.wav').writeAsBytes(wavBytes);
    await File('$base.json').writeAsString(jsonEncode(meta.toJson()));
  }

  Future<List<({Uint8List wav, MetadataPayload meta})>> loadAll() async {
    final dir = await _pendingDir();
    if (!dir.existsSync()) return [];

    final items = <({Uint8List wav, MetadataPayload meta})>[];
    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.wav')) continue;

      final metaFile = File(p.setExtension(entity.path, '.json'));
      if (!metaFile.existsSync()) continue;

      final wav = await entity.readAsBytes();
      final metaMap =
          jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
      items.add((
        wav: wav,
        meta: MetadataPayload.fromJson(metaMap),
      ));
    }
    return items;
  }

  Future<void> delete(String eventoId) async {
    final dir = await _pendingDir();
    final wav = File(p.join(dir.path, '$eventoId.wav'));
    final meta = File(p.join(dir.path, '$eventoId.json'));
    if (wav.existsSync()) await wav.delete();
    if (meta.existsSync()) await meta.delete();
  }

  Future<void> clearAll() async {
    final dir = await _pendingDir();
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }
}
