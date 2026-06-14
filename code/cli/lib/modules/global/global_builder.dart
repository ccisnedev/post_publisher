import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import 'commands/doctor.dart';
import 'commands/help.dart';
import 'commands/init.dart';
import 'commands/tui.dart';
import 'commands/uninstall.dart';
import 'commands/upgrade.dart';
import 'commands/version.dart';

void buildGlobalModule(ModuleBuilder m) {
  m.command<TuiInput, TuiOutput>(
    '',
    (req) => TuiCommand(TuiInput.fromCliRequest(req)),
    description: 'Display Post Publisher status and quick-start help',
  );

  m.command<HelpInput, HelpOutput>(
    'help',
    (req) => HelpCommand(HelpInput.fromCliRequest(req)),
    description: 'Show available commands',
  );

  m.command<InitInput, InitOutput>(
    'init',
    (req) => InitCommand(InitInput.fromCliRequest(req)),
    description: 'Initialize project-level Post Publisher defaults',
  );

  m.command<VersionInput, VersionOutput>(
    'version',
    (req) => VersionCommand(VersionInput.fromCliRequest(req)),
    description: 'Print the current CLI version',
  );

  m.command<DoctorInput, DoctorOutput>(
    'doctor',
    (req) => DoctorCommand(DoctorInput.fromCliRequest(req)),
    description: 'Verify the local setup for LinkedIn authentication and posting',
  );

  m.command<UpgradeInput, UpgradeOutput>(
    'upgrade',
    (req) => UpgradeCommand(UpgradeInput.fromCliRequest(req)),
    description: 'Download and install the latest Post Publisher release',
  );

  m.command<UninstallInput, UninstallOutput>(
    'uninstall',
    (req) => UninstallCommand(UninstallInput.fromCliRequest(req)),
    description: 'Remove Post Publisher from the system',
  );
}