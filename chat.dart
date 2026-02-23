import 'package:flutter/material.dart';
import 'dart:convert'; // לעיבוד JSON
import 'package:http/http.dart' as http;

const baseUrl = "http://localhost:5001/search";

Future<Map<String, dynamic>> callBot(Map body) async {
  final res = await http.post(
    Uri.parse(baseUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (res.statusCode != 200) {
    throw Exception("Server error ${res.statusCode}");
  }

  return jsonDecode(res.body);
}

Future<String> sendMessageToServer(String question) async {
  final url = Uri.parse('http://localhost:5001/search');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'question': question}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['answer'] ?? "No answer";
  } else {
    return "Server error ${response.statusCode}";
  }
}

final TextEditingController _controller = TextEditingController();
List<Map<String, dynamic>> messages = [];

class ChatScreen1 extends StatefulWidget {
  const ChatScreen1({super.key});

  @override
  _ChatScreen1State createState() => _ChatScreen1State();
}

class _ChatScreen1State extends State<ChatScreen1> {
  bool botTyping = false;
  String currentStep = "start";
  List<String> lastOptions = [];
  // רשימה לאחסון ההודעות
  Future<void> sendOption(String opt) async {
    setState(() {
      messages.add({
        "message": opt,
        "senderId": "user",
        "isRagResponse": false,
      });
      botTyping = true;
    });

    final res = await http.post(
      Uri.parse("http://localhost:5001/search"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"step": currentStep, "answer": opt}),
    );

    final data = jsonDecode(res.body);

    setState(() {
      botTyping = false;
      currentStep = data["step"];
      lastOptions = List<String>.from(data["options"] ?? []);

      messages.add({
        "message": data["message"],
        "senderId": "RAG_SERVER",
        "isRagResponse": true,
        "options": data["options"],
      });
    });
  }

  Future<void> startBot() async {
    final res = await http.post(
      Uri.parse("http://localhost:5001/search"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"start": true}),
    );

    final data = jsonDecode(res.body);

    setState(() {
      currentStep = data["step"];
      lastOptions = List<String>.from(data["options"] ?? []);

      messages.add({
        "message": data["message"],
        "isRagResponse": true,
        "options": data["options"],
      });
    });
  }

  @override
  void initState() {
    super.initState();
    startBot();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy),
            SizedBox(width: 8),
            Text('Smart Knowledge Bot'),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xfff5f7fb),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length + (botTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (botTyping && index == messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TypingDots(),
                      ),
                    );
                  }
                  final messageData = messages[index];
                  final isRagResponse = messageData['isRagResponse'];

                  return Align(
                    alignment: isRagResponse
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRagResponse
                              ? Colors.white
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isRagResponse)
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.teal.shade100,
                                    child: Icon(Icons.smart_toy, size: 16),
                                  ),

                                if (isRagResponse) SizedBox(width: 6),

                                Text(
                                  isRagResponse ? "The Bot" : "You",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            isRagResponse
                                ? TypeWriterText(
                                    messageData['message'] ?? '',
                                    style: TextStyle(fontSize: 16),
                                  )
                                : Text(
                                    messageData['message'] ?? '',
                                    style: TextStyle(fontSize: 16),
                                  ),

                            /// ✅ כפתורי בחירה מהשרת (Troubleshooter flow)
                            if (messageData["options"] != null &&
                                (messageData["options"] as List).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: (messageData["options"] as List)
                                      .map<Widget>(
                                        (opt) => ActionChip(
                                          label: Text(opt),
                                          onPressed: () => sendOption(opt),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            // Text(
                            //   messageData['message'] ?? '',
                            //   style: TextStyle(fontSize: 16),
                            //   textDirection: TextDirection.rtl,
                            // ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //   child: Wrap(
            //     spacing: 6,
            //     children: [
            //       _quick("Refund"),
            //       _quick("Shipping"),
            //       _quick("Contact"),
            //     ],
            //   ),
            // ),
            _buildBottomChatField(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomChatField() {
    return Container(
      padding: EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      final message = _controller.text;
                      if (message.isNotEmpty) {
                        setState(() {
                          messages.add({
                            'message': message,
                            'senderId': 'user',
                            'isRagResponse': false,
                          });
                          botTyping = true; // ← כאן בדיוק
                        });

                        _controller.clear();

                        try {
                          final serverResponse = await sendMessageToServer(
                            message,
                          );

                          final extraDelay = (serverResponse.length * 20).clamp(
                            600,
                            2000,
                          );

                          await Future.delayed(
                            Duration(milliseconds: extraDelay),
                          );
                          setState(() {
                            messages.add({
                              'message': serverResponse,
                              'senderId': 'RAG_SERVER',
                              'isRagResponse': true,
                            });
                            botTyping = false; // ← כאן
                          });
                        } catch (e) {
                          print('Error sending message to server: $e');
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quick(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _controller.text = text;
      },
    );
  }
}

class TypeWriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const TypeWriterText(this.text, {this.style, super.key});

  @override
  State<TypeWriterText> createState() => _TypeWriterTextState();
}

class _TypeWriterTextState extends State<TypeWriterText> {
  String shown = "";

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _run() async {
    final chars = widget.text.runes.toList(); // ✅ Unicode safe

    for (final r in chars) {
      await Future.delayed(const Duration(milliseconds: 22));
      if (!mounted) return;
      setState(() {
        shown += String.fromCharCode(r);
      });
    }
  }

  bool _isRTL(String s) {
    return RegExp(r'[\u0590-\u05FF\u0600-\u06FF]').hasMatch(s);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      shown,
      style: widget.style,
      textDirection: _isRTL(widget.text)
          ? TextDirection.rtl
          : TextDirection.ltr,
    );
  }
}

class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController c;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Widget dot(double delay) {
    return ScaleTransition(
      scale: Tween(begin: .35, end: 1.25).animate(
        CurvedAnimation(
          parent: c,
          curve: Interval(delay, delay + .45, curve: Curves.easeOutBack),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: CircleAvatar(radius: 3.5, backgroundColor: Colors.black38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [dot(0.0), dot(0.15), dot(0.30)],
    );
  }
}
