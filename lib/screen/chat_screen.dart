import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isBotTyping = false;

  @override
  void initState() {
    super.initState();
    _addInitialMessage();
  }

  void _addInitialMessage() {
    setState(() {
      _messages.add({
        'sender': 'Bot',
        'message': "Hey there! How could I help you today?",
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    final userMessage = {
      'sender': 'User',
      'message': text,
      'timestamp': DateTime.now(),
    };

    setState(() {
      _messages.add(userMessage);
    });

    _controller.clear();
    _scrollToBottom();

    setState(() {
      _isBotTyping = true;
    });

    final answer = await DatabaseHelper.getAnswerForQuestion(text);

    await Future.delayed(const Duration(seconds: 1));

    final botMessage = {
      'sender': 'Bot',
      'message': answer,
      'timestamp': DateTime.now(),
    };

    setState(() {
      _messages.add(botMessage);
      _isBotTyping = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text("AI Assistant is typing..."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: Image.asset(
                "assets/images/247Logo.jpg",
                width: 60,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: const Text(
          "AI Assistant",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isBotTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }

                final message = _messages[index];
                final isUser = message['sender'] == 'User';
                final timestamp = message['timestamp'] as DateTime?;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          const Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 2),
                            child: Text(
                              "AI Assistant",
                              style:
                                  TextStyle(fontSize: 13, color: Colors.black),
                            ),
                          ),
                        Material(
                          color: isUser
                              ? Colors.blue.shade900
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  message["message"] ?? '',
                                  style: TextStyle(
                                    color: isUser ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                if (timestamp != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      _formatTimestamp(timestamp),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isUser
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: "Ask a question...",
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text.trim()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
