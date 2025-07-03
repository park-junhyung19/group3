import 'package:flutter/material.dart';

// 채팅 메시지 모델
class ChatMessage {
  final String sender;
  final String content;
  final DateTime time;
  final bool isMe;
  final ChatMessageType type;
  final String? fileName;
  final String? fileUrl;

  ChatMessage({
    required this.sender,
    required this.content,
    required this.time,
    required this.isMe,
    this.type = ChatMessageType.text,
    this.fileName,
    this.fileUrl,
  });
}

enum ChatMessageType { text, image, file }

// 채팅방 목록 화면
class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  // 예시 데이터
  final List<Map<String, dynamic>> chatRooms = [
    {
      'name': '접니다 저',
      'lastMessage': 'Screenshot_20250625_034855_KakaoStory1.jpg',
      'lastTime': '오후 12:26',
      'unread': 0,
      'messages': [
        ChatMessage(
          sender: '접니다 저',
          content: '하위하위',
          time: DateTime.now().subtract(const Duration(minutes: 10)),
          isMe: false,
        ),
        ChatMessage(
          sender: '접니다 저',
          content: 'high (1).avif',
          time: DateTime.now().subtract(const Duration(minutes: 9)),
          isMe: false,
          type: ChatMessageType.file,
          fileName: 'high (1).avif',
          fileUrl: '',
        ),
        ChatMessage(
          sender: '접니다 저',
          content: 'ImageFileUsingTCP.jpg',
          time: DateTime.now().subtract(const Duration(minutes: 9)),
          isMe: false,
          type: ChatMessageType.file,
          fileName: 'ImageFileUsingTCP.jpg',
          fileUrl: '',
        ),
        ChatMessage(
          sender: '접니다 저',
          content: 'ImageFileUsingTCP.jpg',
          time: DateTime.now().subtract(const Duration(minutes: 9)),
          isMe: false,
          type: ChatMessageType.image,
          fileName: 'ImageFileUsingTCP.jpg',
          fileUrl: '',
        ),
      ],
    },
    {
      'name': 'saguming11',
      'lastMessage': '야 이 씨발',
      'lastTime': '오후 05:26',
      'unread': 1,
      'messages': [
        ChatMessage(
          sender: 'saguming11',
          content: '야 이 씨발',
          time: DateTime.now().subtract(const Duration(hours: 1)),
          isMe: false,
        ),
      ],
    },
    {
      'name': 'test',
      'lastMessage': 'ㅋㅋ',
      'lastTime': '오후 05:18',
      'unread': 0,
      'messages': [
        ChatMessage(
          sender: 'test',
          content: 'ㅋㅋ',
          time: DateTime.now().subtract(const Duration(hours: 2)),
          isMe: false,
        ),
      ],
    },
    {
      'name': 'saguming1',
      'lastMessage': '어쩌라고 ㅋㅋ',
      'lastTime': '오전 03:15',
      'unread': 0,
      'messages': [
        ChatMessage(
          sender: 'saguming1',
          content: '어쩌라고 ㅋㅋ',
          time: DateTime.now().subtract(const Duration(hours: 3)),
          isMe: false,
        ),
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('채팅', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 채팅방 추가 기능
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        itemCount: chatRooms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, idx) {
          final room = chatRooms[idx];
          return Material(
            color: idx == 2 ? const Color(0xFFE3F2FD) : Colors.white, // 예시: 특정 채팅방 하이라이트
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: Text(room['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                room['lastMessage'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              trailing: Text(room['lastTime'], style: const TextStyle(fontSize: 13, color: Colors.black45)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(
                      roomName: room['name'],
                      messages: List<ChatMessage>.from(room['messages']),
                    ),
                  ),
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          );
        },
      ),
    );
  }
}

// 채팅방 상세 화면
class ChatRoomScreen extends StatefulWidget {
  final String roomName;
  final List<ChatMessage> messages;

  const ChatRoomScreen({
    super.key,
    required this.roomName,
    required this.messages,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text('채팅방', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 채팅방 설정
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: widget.messages.length,
              itemBuilder: (context, idx) {
                final msg = widget.messages[idx];
                return Align(
                  alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: _ChatBubble(msg: msg),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.grey),
                  onPressed: () {
                    // 이미지 첨부
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () {
                    // 파일 첨부
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF1877F2)),
                  onPressed: () {
                    // 메시지 전송
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 채팅 메시지 버블 위젯
class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isFile = msg.type == ChatMessageType.file;
    final isImage = msg.type == ChatMessageType.image;
    final isMe = msg.isMe;

    return Container(
      margin: EdgeInsets.only(
        top: 4, bottom: 10,
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
      ),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF1877F2) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Text(msg.sender, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black54)),
          if (!isMe) const SizedBox(height: 2),
          if (msg.type == ChatMessageType.text)
            Text(msg.content, style: TextStyle(fontSize: 15, color: isMe ? Colors.white : Colors.black)),
          if (isFile)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file, color: isMe ? Colors.white : Colors.blueGrey),
                const SizedBox(width: 6),
                Text(msg.fileName ?? msg.content, style: TextStyle(fontSize: 15, color: isMe ? Colors.white : Colors.blue)),
                const SizedBox(width: 8),
                Icon(Icons.download_rounded, color: isMe ? Colors.white : Colors.blueAccent, size: 18),
              ],
            ),
          if (isImage)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  color: Colors.grey[200],
                  child: msg.fileUrl != null && msg.fileUrl!.isNotEmpty
                      ? Image.network(msg.fileUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(msg.fileName ?? '', style: TextStyle(fontSize: 13, color: isMe ? Colors.white70 : Colors.black54)),
              ],
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : Colors.black38),
            ),
          ),
        ],
      ),
    );
  }
}
