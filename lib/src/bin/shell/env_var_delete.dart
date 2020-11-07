import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/env.dart';
import 'package:process_run/src/common/import.dart';

class ShellEnvVarDeleteCommand extends ShellEnvCommandBase {
  ShellEnvVarDeleteCommand()
      : super(
          name: 'delete',
          description:
              'Delete an environment variable from a user/local config file',
        );

  @override
  void printUsage() {
    stdout.writeln('ds env var delete <name> [<name2>...]');
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    var rest = results.rest;
    if (rest.isEmpty) {
      stderr.writeln('At least 1 arguments expected');
      exit(1);
    } else {
      if (verbose) {
        stdout.writeln('file $label: $envFilePath');
        stdout.writeln('before: ${jsonEncode(ShellEnvironment().vars)}');
      }

      var fileContent = await envFileReadOrCreate();
      var modified = false;
      for (var name in rest) {
        modified = fileContent.deleteVar(name) ?? modified;
      }
      if (modified) {
        if (verbose) {
          stdout.writeln('writing file');
        }
        await fileContent.write();
      }

      // Force reload
      shellEnvironment = null;
      if (verbose) {
        stdout.writeln('After: ${jsonEncode(ShellEnvironment().vars)}');
      }
      return true;
    }
  }
}

/// Direct shell env Var Set run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvVarDeleteCommand().parseAndRun(arguments);
}
