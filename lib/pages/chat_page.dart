import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_daily_planner/components/chat_bubble.dart';
import 'package:smart_daily_planner/components/my_textfield.dart';

import '../services/auth/auth_service.dart';
import '../services/chat/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  final String? receiverName;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
    this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  final FocusNode myFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Auto scroll when entering the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });

    // Auto scroll when keyboard opens
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });
      }
    });
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverID,
        _messageController.text,
      );

      _messageController.clear();

      // Immediately scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName ?? widget.receiverEmail),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: buildMessageList()),
          buildUserInput(),
        ],
      ),
    );
  }

  // MESSAGE LIST STREAM
  Widget buildMessageList() {
    String currentUserID = _authService.getCurrentUser()!.uid;

    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverID, currentUserID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading messages"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Auto scroll AFTER messages load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 20),
          children:
              snapshot.data!.docs.map((e) => buildMessageItem(e)).toList(),
        );
      },
    );
  }

  // EACH CHAT BUBBLE
  Widget buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isSender = data['senderID'] == _authService.getCurrentUser()!.uid;

    return Container(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ChatBubble(
        message: data['message'],
        isSender: isSender,
        timestamp: data['timestamp'],
      ),
    );
  }

  // USER INPUT FIELD
  Widget buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, left: 10),
      child: Row(
        children: [
          Expanded(
            child: MyTextfield(
              hintText: "Type a message",
              obscureText: false,
              focusNode: myFocusNode,
              controller: _messageController,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
