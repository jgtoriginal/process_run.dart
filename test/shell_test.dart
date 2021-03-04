@TestOn('vm')
library process_run.test.shell_test;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/dartbin_cmd.dart'
    show parseDartBinVersionOutput;
import 'package:test/test.dart';

import 'hex_utils.dart';

@deprecated
bool devTrue = true;
//bool debug = devTrue;
bool debug = false;

// To set in both variable for a full empty environment
var dummyEnvPath = join('test', 'data', 'test_env.yaml_dummy');
ShellEnvironment newEnvNoOverride() =>
    ShellEnvironment(environment: <String, String>{
      userEnvFilePathEnvKey: dummyEnvPath,
      localEnvFilePathEnvKey: dummyEnvPath
    });

void main() {
  group('Shell', () {
    test('public', () {
      // ignore: unnecessary_statements
      getFlutterBinVersion;
      // ignore: unnecessary_statements
      getFlutterBinChannel;
      isFlutterSupported;
      isFlutterSupportedSync;
      dartVersion;
      dartChannel;
      // ignore: unnecessary_statements
      dartChannelStable;
      // ignore: unnecessary_statements
      dartChannelBeta;
      // ignore: unnecessary_statements
      dartChannelDev;
      // ignore: unnecessary_statements
      dartChannelMaster;

      // ignore: unnecessary_statements
      promptConfirm;
      // ignore: unnecessary_statements
      prompt;
      // ignore: unnecessary_statements
      promptTerminate;

      // ignore: unnecessary_statements
      ShellException;
      // ignore: unnecessary_statements
      ShellLinesController;
      // ignore: unnecessary_statements
      which;
      // ignore: unnecessary_statements
      whichSync;
      // ignore: unnecessary_cast
      (null as Process)?.errLines;
      // ignore: unnecessary_cast
      (null as List<ProcessResult>)?.outText;
      // ignore: unnecessary_cast
      (null as List<ProcessResult>)?.outLines;
      // ignore: unnecessary_cast
      (null as List<ProcessResult>)?.errText;
      // ignore: unnecessary_cast
      (null as List<ProcessResult>)?.errLines;
    });

    test('arguments', () async {
      var shell = Shell(verbose: debug);
      var text = 'Hello  world';
      var results = await shell.run('''
# this will print 'Helloworld'
dart run example/echo.dart -o Hello  world
dart run example/echo.dart -o $text
# this will print 'Hello  world'
dart run example/echo.dart -o 'Hello  world'
dart run example/echo.dart -o 'Hello  world'
dart run example/echo.dart -o ${shellArgument(text)}
dart run example/echo.dart -o éà
''');
      expect(results[0].stdout.toString().trim(), 'Helloworld');
      expect(results[1].stdout.toString().trim(), 'Helloworld');
      expect(results[2].stdout.toString().trim(), 'Hello  world');
      expect(results[3].stdout.toString().trim(), 'Hello  world');
      expect(results[4].stdout.toString().trim(), 'Hello  world');
      if (!Platform.isWindows) {
        expect(results[5].stdout.toString().trim(), 'éà');
      }
      expect(results.length, 6);
    });

    test('outLines, errLines', () async {
      var shell = Shell(verbose: debug, runInShell: true);

      var results = await shell.run(
          'dart run example/echo.dart --stdout-hex ${bytesToHex(utf8.encode('Hello\nWorld'))}');
      //TODO test other platforms
      if (Platform.isLinux) {
        expect(results.outLines, ['Hello', 'World']);
        expect(results.errLines, []);
      }
      results = await shell.run('dart run example/echo.dart -e Hello');
      //TODO test other platforms
      if (Platform.isLinux) {
        expect(results.outLines, []);
        expect(results.errLines, ['Hello']);
      }
      results = await shell.run('''
# This is a 2 commands file

dart run example/echo.dart -o Hello

dart run example/echo.dart -e World
''');
      //TODO test other platforms
      if (Platform.isLinux) {
        expect(results.outLines, ['Hello']);
        expect(results.errLines, ['World']);
      }
    });

    test('backslash', () async {
      var shell = Shell(verbose: debug);
      var weirdText = r'a/\b c/\d';
      var results = await shell.run('''
dart run example/echo.dart -o $weirdText
dart run example/echo.dart -o ${shellArgument(weirdText)}

''');

      expect(results[0].stdout.toString().trim(), r'a/\bc/\d');
      expect(results[1].stdout.toString().trim(), r'a/\b c/\d');
      expect(results.length, 2);
    });
    test('dart', () async {
      var shell = Shell(verbose: debug);
      var results = await shell.run('''dart --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('dart runExecutableArguments', () async {
      var shell = Shell(verbose: debug);
      var result = await shell.runExecutableArguments('dart', ['--version']);
      expect(result.exitCode, 0);
    });
    test('dart runExecutableArguments bad arg', () async {
      var shell = Shell(verbose: debug);
      try {
        await shell.runExecutableArguments('dart', ['--bad-arg']);
        fail('shoud fail');
      } on ShellException catch (e) {
        expect(e.result.exitCode, 255);
      }
    });

    test('kill simple', () async {
      try {
        await () async {
          var shell = Shell().cd('example');
          Future future;
          try {
            future = shell.run('dart run echo.dart --wait 30000');
            await future.timeout(const Duration(milliseconds: 15000));
            fail('should fail');
          } on TimeoutException catch (_) {
            // 1: TimeoutException after 0:00:02.000000: Future not completed
            //devPrint('1: $e');
          }
          try {
            shell.kill();
            await future;
            fail('should fail');
          } on ShellException catch (_) {
            // 2: ShellException(dart run echo.dart --wait 3000, exitCode -15, workingDirectory:
            // devPrint('2: $_');
          }
        }()
            .timeout(const Duration(seconds: 30));
      } on TimeoutException catch (e) {
        stderr.writeln('TimeOutException $e');
        stderr.writeln('Allowed: could happen on CI');
      }
    }, timeout: const Timeout(Duration(seconds: 50)));
    test('kill complex', () async {
      try {
        await () async {
          var shell = Shell().cd('example');
          Future future;
          try {
            future = shell.run('dart run echo.dart --wait 3000');
            await future.timeout(const Duration(milliseconds: 2000));
            fail('should fail');
          } on TimeoutException catch (_) {
            // 1: TimeoutException after 0:00:02.000000: Future not completed
            shell.kill();
            //devPrint('1: $e');
          }
          try {
            await future;
            fail('should fail');
          } on ShellException catch (_) {
            // 2: ShellException(dart run echo.dart --wait 3000, exitCode -15, workingDirectory:
            // devPrint('2: $e');
          }

          try {
            var future = shell.run('dart run echo.dart --wait 10000');
            await Future.delayed(const Duration(milliseconds: 3000));
            shell.kill();
            await future.timeout(const Duration(milliseconds: 8000));
            fail('should fail');
          } on ShellException catch (_) {
            // devPrint('3: $e');
          }

          try {
            // Killing before calling
            future = shell
                .run('dart run echo.dart --wait 9000')
                .timeout(const Duration(milliseconds: 7000));
            shell.kill();
            await future;
            fail('should fail');
          } on ShellException catch (_) {
            // devPrint('3: $e');
          }
        }()
            .timeout(const Duration(seconds: 40));
      } on TimeoutException catch (e) {
        stderr.writeln('TimeOutException $e');
        stderr.writeln('Allowed: could happen on CI');
      }
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('Shell Lines Controller', () async {
      var linesController = ShellLinesController();
      var shell =
          Shell(stdout: linesController.sink, verbose: false).cd('example');
      await shell.run('dart run echo.dart some_text');
      linesController.close();
      expect(await linesController.stream.toList(), ['some_text']);

      linesController = ShellLinesController();
      shell = Shell(stdout: linesController.sink, verbose: false).cd('example');
      await shell.run('dart run echo.dart some_text1');
      await shell.run('''
      dart run echo.dart some_text2
      dart run echo.dart some_text3
      ''');
      linesController.close();
      expect(await linesController.stream.toList(),
          ['some_text1', 'some_text2', 'some_text3']);
    });

    test('cd', () async {
      var shell = Shell(verbose: debug);

      var results = await shell.run('dart test/src/current_dir.dart');

      expect(results[0].stdout.toString().trim(), Directory.current.path);

      results = await shell.cd('test/src').run('''
dart current_dir.dart
''');
      expect(results[0].stdout.toString().trim(),
          join(Directory.current.path, 'test', 'src'));
    });

    test('path', () {
      var shell = Shell();
      expect(shell.path, isNotEmpty);
      shell = shell.pushd('test');
      expect(basename(shell.path), 'test');
    });
    test('pushd', () async {
      var shell = Shell(verbose: debug);

      var results = await shell.run('dart test/src/current_dir.dart');
      expect(results[0].stdout.toString().trim(), Directory.current.path);

      shell = shell.pushd('test/src');
      results = await shell.run('dart current_dir.dart');
      expect(results[0].stdout.toString().trim(),
          join(Directory.current.path, 'test', 'src'));

      // pop once
      shell = shell.popd();
      results = await shell.run('dart test/src/current_dir.dart');
      expect(results[0].stdout.toString().trim(), Directory.current.path);

      // pop once
      expect(shell.popd(), isNull);
    });
    test('dart_no_path', () async {
      var environment = Map<String, String>.from(shellEnvironment)
        ..remove('PATH');
      var shell = Shell(environment: environment, verbose: debug);
      var results = await shell.run('''dart --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('pub_no_path', () async {
      print(userPaths);
      var environment = Map<String, String>.from(shellEnvironment)
        ..remove('PATH');
      var shell = Shell(environment: environment, verbose: false);
      var results = await shell.run('''pub --version''');
      expect(results.length, 1);
      expect(results.first.exitCode, 0);
    });

    test('escape backslash', () async {
      var shell = Shell(verbose: debug);
      var results = await shell.run('''echo "\\"''');
      expect(results[0].stdout.toString().trim(), '\\');
    });
    test('others', () async {
      try {
        var shell = Shell(verbose: false, runInShell: Platform.isWindows);
        await shell.run('''
echo Hello world
firebase --version
adb --version
_tekartik_dummy_app_that_does_not_exits
''');
        fail('should fail');
      } on Exception catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
    }); // skip windows for now
  });

  Future _testCommand(String command) async {
    var shell = Shell(verbose: debug);
    try {
      await shell.run(command);
    } on ShellException catch (_) {
      // we only accept shell exception here
    }
  }

  test('various command', () async {
    // that can be installed or not
    await _testCommand('firebase --version'); // firebase.cmd on windows
    await _testCommand('flutter --version'); // flutter.bat on windows
    await _testCommand('dart --version'); // dart.exe on windows
    await _testCommand(
        '${shellArgument(dartExecutable)} --version'); // dart.exe on windows
    await _testCommand('pub --version'); // dart.exe on windows
    // on windows, system command or alias in PowerShell
    await _testCommand('echo Hello world');
  });

  test('echo', () async {
    await _testCommand('echo Hello world'); // alias to Write-Output
    await _testCommand('echo Hello world'); // alias to Write-Output
  });

  test('pipe', () async {
    var dir = join('.dart_tool', 'process_run', 'test');
    await Directory(dir).create(recursive: true);
    var file = File(join(dir, 'echo.output'));
    var shell = Shell();

    // Write to file
    await file.writeAsString(
        (await shell.run('echo Hello world')).first.stdout.toString());

    // Append to file
    await file.writeAsString(
        (await shell.run('echo Hello world')).first.stdout.toString(),
        mode: FileMode.append);

    var separator = Platform.isWindows ? '\r\n' : '\n';
    expect(await file.readAsString(),
        'Hello world${separator}Hello world$separator');
  });

  test('user', () {
    if (Platform.isWindows) {
      expect(userHomePath, Platform.environment['USERPROFILE']);
      expect(userAppDataPath, Platform.environment['APPDATA']);
    } else {
      expect(userHomePath, Platform.environment['HOME']);
      expect(userAppDataPath, join(Platform.environment['HOME'], '.config'));
    }
  });

  test('userLoadEnvFile', () async {
    //print(a);
    var path = join('test', 'data', 'test_env1.yaml');
    userLoadEnvFile(path);
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
    path = join('test', 'data', 'test_env_dummy_file.yaml');
    userLoadEnvFile(path);
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
  });

  test('userLoadEnv', () async {
    userLoadEnv(vars: {'test': '1'}, paths: ['my_path']);
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
    userLoadEnv();
    expect(userEnvironment['test'], '1');
    expect(userPaths, contains('my_path'));
  });

  test('ShellException bad command', () async {
    var shell = Shell();
    try {
      await shell.run('dummy_command_that_does_not_exist');
    } on ShellException catch (e) {
      expect(e.message.contains('workingDirectory'), isTrue);
    }
  });
  test('ShellException bad directory', () async {
    var shell = Shell(workingDirectory: 'dummy_directory_that_does_not_exist');
    try {
      await shell.run('dart --version');
    } on ShellException catch (e) {
      expect(e.message.contains('workingDirectory'), isTrue);
    }
  });
  test('User path', () async {
    // TODO test on other platform
    if (Platform.isLinux) {
      var environment = {
        'PATH': '${absolute('test/src')}:${platformEnvironment['PATH']}'
      };
      print(environment);
      var shell =
          Shell(environment: environment, includeParentEnvironment: false);
      await shell.run('current_dir');
    }
  });
  test('flutter_resolve', () async {
    // Edge case finding flutter from dart
    if (Platform.isLinux) {
      var paths = platformEnvironment['PATH'].split(':')
        ..removeWhere((element) => element.endsWith('flutter/bin'));

      paths.insert(0, dartSdkBinDirPath);
      print(paths);
      var environment = {'PATH': '${paths.join(':')}'};
      print(environment);
      var shell =
          Shell(environment: environment, includeParentEnvironment: false);
      await shell.run('flutter --version');
    }
  },
      // skip: !isFlutterSupportedSync ||
      skip: true);
  // This is plain wrong now...assumed dart below flutter which will no longer be the case

  test('flutter info', () async {
    expect(await getFlutterBinVersion(), isNotNull);
    expect(await getFlutterBinChannel(), isNotNull);
  }, skip: !isFlutterSupportedSync);

  test('dart version', () async {
    // Try to get the version in 2 different ways
    var sh = Shell();

    var whichDart = await which('dart');
    var resolvedVersion = parseDartBinVersionOutput(
        (await sh.runExecutableArguments(dartExecutable, ['--version']))
            .stderr
            .toString());
    var whichVersion = parseDartBinVersionOutput(
        (await sh.runExecutableArguments(whichDart, ['--version']))
            .stderr
            .toString());
    var version = parseDartBinVersionOutput(
        (await sh.runExecutableArguments('dart', ['--version']))
            .stderr
            .toString());
    expect(version, resolvedVersion);
    expect(version, whichVersion);
  });

  test('verbose non ascii char', () async {
    var controller = ShellLinesController();
    var shell = Shell(
        stdout: controller.sink,
        verbose: true,
        environment: ShellEnvironment()
          ..aliases['echo'] = 'dart run example/echo.dart -o');
    await shell.run('echo 你好é');
    controller.close();
    if (!Platform.isWindows) {
      expect(await controller.stream.toList(),
          ['\$ dart run example/echo.dart -o 你好é', '你好é']);
    }
  });
}
