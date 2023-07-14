import 'package:flutter/material.dart';
import "package:flutter_dotenv/flutter_dotenv.dart";
import 'package:velocity_x/velocity_x.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

import 'chat_message.dart';
import 'three_dots.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  late OpenAI? chatGPT;
  final bool _isImageSearch = false;

  bool _isTyping = false;

  @override
  void initState() {
    chatGPT = OpenAI.instance.build(
        token: dotenv.env['OPEN_AI_API_KEY'],
        baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 60)),
        isLog: true);
    super.initState();
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    ChatMessage message = ChatMessage(
      text: _controller.text,
      sender: 'user',
    );

    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    _controller.clear();

    // if (_isImageSearch) {
    //   final request = GenerateImage(message.text, 1, size: "256x256");

    //   final response = await chatGPT!.generateImage(request);
    //   Vx.log(response!.data!.last!.url!);
    //   insertNewData(response.data!.last!.url!, isImage: true);
    // } else {
    final request = CompleteText(
      prompt: message.text,
      model: Model.textCurie001,
      maxTokens: 200,
    );

    final response = await chatGPT!.onCompletion(request: request);
    Vx.log(response!.choices[0].text);
    insertNewData(response.choices[0].text, isImage: false);
  }

  void insertNewData(String response, {bool isImage = false}) {
    Vx.log(response);
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "bot",
      // isImage: isImage,
    );

    setState(() {
      _isTyping = false;
      _messages.insert(0, botMessage);
    });
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (value) => _sendMessage(),
            decoration: const InputDecoration.collapsed(
                hintText: "Question/description"),
          ),
        ),
        ButtonBar(
          children: [
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                // _isImageSearch = false;
                _sendMessage();
              },
            ),
          ],
        ),
      ],
    ).px16();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChatGPT App')),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
                child: ListView.builder(
              reverse: true,
              padding: Vx.m1,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index].p16();
              },
            )),
            if (_isTyping) const ThreeDots(),
            const Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
              ),
              child: _buildTextComposer(),
            )
          ],
        ),
      ),
    );
  }
}
