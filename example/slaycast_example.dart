import 'dart:io';

import 'package:slaycast/slaycast.dart';

void main() async {
  final slay = Slaycast(auth: RaycastAuth(apiKey: '', signature: ''));
  final history = <ChatMessage>[];

  while (true) {
    stdout.write('>>> ');
    final input = stdin.readLineSync()!;

    if (input == 'exit') {
      break;
    }

    final stream = slay.chat(
      history..add(ChatMessage.text(input)),
      model: Model(
        name: 'gpt-4',
        provider: 'openai',
      ),
    );

    var response = '';

    await for (final chunk in stream) {
      response += chunk.text;
      stdout.write(chunk.text);
    }

    history.add(ChatMessage.text(response, author: 'assistant'));
    stdout.write('\n');
  }
}
