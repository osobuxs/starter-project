import 'dart:io';

Future<void> main() async {
  final projectDir = Directory.current;
  final pubspecFile = File('${projectDir.path}/pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    stderr.writeln(
      '❌ No se encontró pubspec.yaml. Ejecutá este comando desde frontend/.',
    );
    exitCode = 1;
    return;
  }

  final version = _readVersion(pubspecFile.readAsStringSync());
  if (version == null) {
    stderr.writeln('❌ No se pudo resolver la versión desde pubspec.yaml');
    exitCode = 1;
    return;
  }

  final flutterCmd = Platform.isWindows ? 'flutter.bat' : 'flutter';

  stdout.writeln('🔧 Resolviendo dependencias...');
  final pubGet = await Process.start(flutterCmd, ['pub', 'get']);
  await stdout.addStream(pubGet.stdout);
  await stderr.addStream(pubGet.stderr);
  final pubGetCode = await pubGet.exitCode;
  if (pubGetCode != 0) {
    stderr.writeln('❌ flutter pub get falló (code $pubGetCode).');
    exitCode = pubGetCode;
    return;
  }

  stdout.writeln('📦 Construyendo APK release...');
  final build = await Process.start(flutterCmd, ['build', 'apk', '--release']);
  await stdout.addStream(build.stdout);
  await stderr.addStream(build.stderr);
  final buildCode = await build.exitCode;
  if (buildCode != 0) {
    stderr.writeln('❌ flutter build apk falló (code $buildCode).');
    exitCode = buildCode;
    return;
  }

  final sourceApk = File(
    '${projectDir.path}/build/app/outputs/flutter-apk/app-release.apk',
  );
  if (!sourceApk.existsSync()) {
    stderr.writeln('❌ No se encontró app-release.apk después del build.');
    exitCode = 1;
    return;
  }

  final apkDir = Directory('${projectDir.path}/apk');
  if (!apkDir.existsSync()) {
    apkDir.createSync(recursive: true);
  }

  final safeVersion = version.replaceAll('+', '_');
  final namedOutput = File(
    '${apkDir.path}/symmetry-news-v$safeVersion-release.apk',
  );
  final latestOutput = File('${apkDir.path}/latest-release.apk');

  sourceApk.copySync(namedOutput.path);
  sourceApk.copySync(latestOutput.path);

  stdout.writeln('✅ APK generado correctamente');
  stdout.writeln('   - ${namedOutput.path}');
  stdout.writeln('   - ${latestOutput.path}');
}

String? _readVersion(String content) {
  final versionLine = RegExp(
    r'^version\s*:\s*([^\s]+)\s*$',
    multiLine: true,
  ).firstMatch(content);
  return versionLine?.group(1)?.trim();
}
