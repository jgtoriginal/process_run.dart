@TestOn("vm")
library process_run.which_test;

import 'dart:io';
import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/which.dart';

void main() {
  group('which', () {
    test('dart', () async {
      var env = {'PATH': dartSdkBinDirPath};
      var dartExecutable = whichSync('dart', env: env);
      expect(dartExecutable, isNotNull);
      print(dartExecutable);
      var cmd = ProcessCmd(dartExecutable, ['--version']);
      ProcessResult result = await runCmd(cmd);
      expect(result.stderr.toLowerCase(), contains("dart"));
      expect(result.stderr.toLowerCase(), contains("version"));
    });

    test('no_env', () {
      var dartExecutableFilename = whichSync('dart', env: <String, String>{});
      expect(dartExecutableFilename, isNull);
      expect(whichSync('pub', env: <String, String>{}), isNull);

      dartExecutableFilename = whichSync('dart',
          env: <String, String>{}, paths: [dirname(dartExecutable)]);
      expect(dartExecutableFilename, isNotNull);
      expect(
          whichSync('pub',
              env: <String, String>{}, paths: [dirname(dartExecutable)]),
          isNotNull);
    });

    test('echo', () async {
      if (Platform.isWindows) {
        expect(whichSync('echo'), isNull);
      }
    });
  });
}
