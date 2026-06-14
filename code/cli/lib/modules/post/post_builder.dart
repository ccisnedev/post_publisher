import 'package:modular_cli_sdk/modular_cli_sdk.dart';

import 'commands/text.dart';
import 'commands/document.dart';
import 'commands/image.dart';

void buildPostModule(ModuleBuilder m) {
  m.command<PostTextInput, PostTextOutput>(
    'text',
    (req) => PostTextCommand(PostTextInput.fromCliRequest(req)),
    description: 'Publish a text post as yourself or one of your organizations',
  );

  m.command<PostImageInput, PostImageOutput>(
    'image',
    (req) => PostImageCommand(PostImageInput.fromCliRequest(req)),
    description: 'Publish an image post from a local file',
  );

  m.command<PostDocumentInput, PostDocumentOutput>(
    'document',
    (req) => PostDocumentCommand(PostDocumentInput.fromCliRequest(req)),
    description: 'Publish a PDF document post from a local file',
  );
}