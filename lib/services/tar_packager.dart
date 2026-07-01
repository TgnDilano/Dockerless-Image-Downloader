import 'dart:io';
import 'package:archive/archive.dart';

typedef LogCallback = void Function(String line);

class TarPackager {
  static Future<String> packageToTar({
    required String directoryPath,
    required String imageName,
    required String tag,
    LogCallback? logCallback,
  }) async {
    void log(String line) => logCallback?.call(line);

    log('[Tar] Packaging directory: $directoryPath');
    log('[Tar] Image: $imageName, Tag: $tag');

    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      log('[Tar] ERROR: Directory does not exist: $directoryPath');
      throw Exception('Directory does not exist: $directoryPath');
    }
    log('[Tar] Directory exists, listing contents...');
    await for (final entry in dir.list()) {
      log('[Tar]   ${entry is Directory ? "[DIR]" : "[FILE]"} ${entry.path}');
    }

    final safeName = imageName.replaceAll('/', '_');
    final parentDir = dir.parent.path;
    final tarFileName = '${safeName}_$tag.tar';
    final tarPath = '$parentDir${Platform.pathSeparator}$tarFileName';
    log('[Tar] Target tar path: $tarPath');

    final encoder = TarEncoder();
    final archive = Archive();

    log('[Tar] Adding directory to archive...');
    await _addDirectoryToArchive(archive, dir, '', logCallback: logCallback);
    log('[Tar] Archive entries: ${archive.files.length}');

    log('[Tar] Encoding archive...');
    final encodedData = encoder.encode(archive);
    log('[Tar] Encoded size: ${encodedData.length} bytes');

    log('[Tar] Writing to file...');
    await File(tarPath).writeAsBytes(encodedData);
    log('[Tar] Tar file created: $tarPath');

    return tarPath;
  }

  static Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory dir,
    String basePath, {
    LogCallback? logCallback,
  }) async {
    void log(String line) => logCallback?.call(line);
    int fileCount = 0;

    await for (final entity in dir.list()) {
      final entityPath = entity.path;
      final relativeName = entityPath.substring(dir.path.length + 1);
      final relativePath = basePath.isEmpty ? relativeName : '$basePath/$relativeName';

      if (entity is File) {
        fileCount++;
        log('[Tar] Adding file [$fileCount]: $relativePath');
        final bytes = await entity.readAsBytes();
        log('[Tar]   File size: ${bytes.length} bytes');
        final archiveFile = ArchiveFile(relativePath, bytes.length, bytes);
        archive.addFile(archiveFile);
      } else if (entity is Directory) {
        log('[Tar] Adding directory entry: $relativePath');
        final archiveFile = ArchiveFile(relativePath, 0, []);
        archive.addFile(archiveFile);
        await _addDirectoryToArchive(archive, entity, relativePath, logCallback: logCallback);
      }
    }
  }
}
