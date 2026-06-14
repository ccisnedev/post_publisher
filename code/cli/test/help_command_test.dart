import 'package:post_publisher/modules/global/commands/help.dart';
import 'package:test/test.dart';

void main() {
  test('help output documents auth and post commands', () async {
    final output = await HelpCommand(HelpInput()).execute();

    expect(output.text, contains('auth login'));
    expect(output.text, contains('auth signin'));
    expect(output.text, contains('post text'));
  });
}