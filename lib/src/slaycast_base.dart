import 'dart:convert';
import 'dart:io';

class Slaycast {
  final Uri baseUrl = Uri.https('backend.raycast.com');
  final HttpClient _client = HttpClient();
  final RaycastAuth auth;

  Slaycast({required this.auth});

  Stream<CompleteionChunk> chat(
    List<ChatMessage> messages, {
    required Model model,
    String source = 'ai_chat',
    String locale = 'en-BE',
    String systemInstruction = 'markdown',
    double temperature = 0.5,
  }) async* {
    final url = baseUrl.resolve('/api/v1/ai/chat_completions');

    final request = await _client.postUrl(url);
    request.headers
      ..contentType = ContentType.json
      ..add('user-agent', 'Raycast/1.65.0 (macOS Version 14.1.2 (Build 23B92))')
      ..add('authorization', auth.apiKey)
      ..add('x-raycast-signature', auth.signature);

    request.write(
      jsonEncode(
        {
          "debug": false,
          "locale": locale,
          "messages": [for (final message in messages) message.toJson()],
          "model": model.name,
          "provider": model.provider,
          "source": source,
          "system_instruction": systemInstruction,
          "temperature": temperature,
        },
      ),
    );

    final response = await request.close();

    await for (final chunk in response.transform(utf8.decoder)) {
      final raw = chunk
          .replaceAll('data: ', '')
          .split('\n')
          .where((e) => e.isNotEmpty && e.startsWith('{') && e.endsWith('}'));

      yield* Stream.fromIterable([
        for (final part in raw) CompleteionChunk.fromJson(jsonDecode(part))
      ]);
    }
  }
}

class RaycastAuth {
  final String apiKey;
  final String signature;

  RaycastAuth({required this.apiKey, required this.signature});
}

class Model {
  final String name;
  final String provider;

  const Model({required this.name, required this.provider});
}

class ChatMessage {
  final String author;
  final Map<String, dynamic> content;

  const ChatMessage({required this.author, required this.content});

  Map<String, dynamic> toJson() {
    return {'author': author, 'content': content};
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(author: json['author'], content: json['content']);
  }

  factory ChatMessage.text(String text, {String author = 'user'}) {
    return ChatMessage(author: author, content: {'text': text});
  }
}

class CompleteionChunk {
  final String text;
  final String? finishReason;

  const CompleteionChunk({required this.text, this.finishReason});

  factory CompleteionChunk.fromJson(Map<String, dynamic> json) {
    return CompleteionChunk(
      text: json['text'],
      finishReason: json['finish_reason'],
    );
  }
}
