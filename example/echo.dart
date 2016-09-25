#!/usr/bin/env dart
library tekartik_process.bin.echo;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

import 'hex_utils.dart';

Version version = new Version(0, 1, 0);

String get currentScriptName => basenameWithoutExtension(Platform.script.path);

/*
Global options:
-h, --help          Usage help
-o, --stdout        stdout content as string
-p, --stdout-hex    stdout as hexa string
-e, --stderr        stderr content as string
-f, --stderr-hex    stderr as hexa string
-i, --stdin         Handle first line of stdin
-x, --exit-code     Exit code to return
    --version       Print the command version
*/

///
/// write rest arguments as lines
///
main(List<String> arguments) async {
  //setupQuickLogging();

  ArgParser parser = new ArgParser(allowTrailingOptions: false);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag('verbose', abbr: 'v', help: 'Verbose', negatable: false);
  parser.addOption('stdout',
      abbr: 'o', help: 'stdout content as string', defaultsTo: null);
  parser.addOption('stdout-hex',
      abbr: 'p', help: 'stdout as hexa string', defaultsTo: null);
  parser.addOption('stderr',
      abbr: 'e', help: 'stderr content as string', defaultsTo: null);
  parser.addOption('stderr-hex',
      abbr: 'f', help: 'stderr as hexa string', defaultsTo: null);
  parser.addFlag('stdin',
      abbr: 'i', help: 'Handle first line of stdin', negatable: false);
  parser.addOption('exit-code', abbr: 'x', help: 'Exit code to return');
  parser.addFlag('version',
      help: 'Print the command version', negatable: false);

  ArgResults _argsResult = parser.parse(arguments);

  bool help = _argsResult['help'];
  bool verbose = _argsResult['verbose'];

  _printUsage() {
    stdout.writeln('Echo utility');
    stdout.writeln();
    stdout.writeln('Usage: ${currentScriptName} <command> [<arguments>]');
    stdout.writeln();
    stdout.writeln('Example: ${currentScriptName} -o "Hello world"');
    stdout.writeln('will display "Hellow world"');
    stdout.writeln();
    stdout.writeln("Global options:");
    stdout.writeln(parser.usage);
  }

  if (help) {
    _printUsage();
    return;
  }

  bool displayVersion = _argsResult['version'];

  if (displayVersion) {
    stdout.write('${currentScriptName} version ${version}');
    stdout.writeln('VM: ${Platform.resolvedExecutable} ${Platform.version}');
    return;
  }

  // handle stdin if asked for it
  if (_argsResult['stdin']) {
    if (verbose) {
      //stderr.writeln('stdin  $stdin');
      //stderr.writeln('stdin  ${await stdin..isEmpty}');
    }
    String lineSync = stdin.readLineSync();
    if (lineSync != null) {
      stdout.write(lineSync);
    }
  }
  // handle stdout
  String outputText = _argsResult['stdout'];
  if (outputText != null) {
    stdout.write(outputText);
  }
  String hexOutputText = _argsResult['stdout-hex'];
  if (hexOutputText != null) {
    stdout.add(hexToBytes(hexOutputText));
  }
  // handle stderr
  String stderrText = _argsResult['stderr'];
  if (stderrText != null) {
    stderr.write(stderrText);
  }
  String stderrHexTest = _argsResult['stderr-hex'];
  if (stderrHexTest != null) {
    stderr.add(hexToBytes(stderrHexTest));
  }

  // handle the rest, default to output
  for (String rest in _argsResult.rest) {
    stdout.writeln(rest);
  }

  // exit code!
  String exitCodeText = _argsResult['exit-code'];
  if (exitCodeText != null) {
    exit(int.parse(exitCodeText));
  }
}
