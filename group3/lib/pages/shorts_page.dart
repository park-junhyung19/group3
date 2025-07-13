import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({super.key});

  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  final _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> _shorts = [];

  @override
  void initState() {
    super.initState();
    _fetchShorts();
  }

  Future<void> _fetchShorts() async {
    final res = await http.get(Uri.parse('http://192.168.0.53:8080/api/posts/shorts'));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      print('[DEBUG] 숏폼 개수: ${data.length}');
      setState(() {
        _shorts = data.cast<Map<String, dynamic>>();
      });
    } else {
      print('[ERROR] 숏폼 로딩 실패: ${res.statusCode} ${res.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _shorts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _shorts.length,
              itemBuilder: (context, index) {
                return ShortVideoPlayer(post: _shorts[index]);
              },
            ),
    );
  }
}

class ShortVideoPlayer extends StatefulWidget {
  final Map<String, dynamic> post;
  const ShortVideoPlayer({super.key, required this.post});

  @override
  State<ShortVideoPlayer> createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends State<ShortVideoPlayer> {
  late VideoPlayerController _controller;
  final _storage = const FlutterSecureStorage();
  final TextEditingController _commentController = TextEditingController();

  bool isLiked = false;
  int likeCount = 0;
  List<dynamic> comments = [];
  bool isPostingComment = false;

  @override
  void initState() {
    super.initState();
    final videoPath = widget.post['videoPath'] ?? '';
    _controller = VideoPlayerController.network('http://192.168.0.53:8080$videoPath')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });

    _fetchPostDetail();
  }

  Future<Map<String, String>?> _getAuthHeader() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) return null;
    final decoded = JwtDecoder.decode(token);
    return {
      'Authorization': 'Bearer $token',
      'userEmail': decoded['sub'],
    };
  }

  Future<void> _fetchPostDetail() async {
    final postId = widget.post['id'];
    if (postId == null) return;

    final url = Uri.parse('http://192.168.0.53:8080/api/posts/$postId');
    final res = await http.get(url);
    print('[DEBUG] 요청 URL: $url');
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      print('[DEBUG] 게시글 상세: $data');
      setState(() {
        comments = data['comments'] ?? [];
        likeCount = data['likeCount'] ?? 0;
        isLiked = data['likedByMe'] ?? false;
      });
      print('[DEBUG] 댓글 수: ${comments.length}');
    } else {
      print('[ERROR] 게시글 상세 조회 실패: ${res.statusCode}, ${res.body}');
    }
  }

  Future<void> _toggleLike() async {
    final headers = await _getAuthHeader();
    final postId = widget.post['id'];
    final userEmail = headers?['userEmail'];
    final token = headers?['Authorization'];
    if (postId != null && userEmail != null && token != null) {
      final url = Uri.parse('http://192.168.0.53:8080/api/likes/$postId');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': token,
        },
        body: 'userEmail=$userEmail',
      );
      print('[DEBUG] 좋아요 응답: ${res.statusCode}, ${res.body}');
      if (res.statusCode == 200) {
        final count = int.tryParse(res.body) ?? likeCount;
        setState(() {
          isLiked = !isLiked;
          likeCount = count;
        });
      }
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final headers = await _getAuthHeader();
    final postId = widget.post['id'];
    final token = headers?['Authorization'];
    if (postId == null || token == null) return;

    setState(() => isPostingComment = true);
    final res = await http.post(
      Uri.parse('http://192.168.0.53:8080/api/posts/$postId/comments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode({'content': content}),
    );

    print('[DEBUG] 댓글 전송 결과: ${res.statusCode}, ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      _commentController.clear();
      _fetchPostDetail();
    }

    setState(() => isPostingComment = false);
  }

  // 핵심 수정 부분만 발췌:

void _showCommentSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black87,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(width: 40, height: 4, color: Colors.grey[600]),
                const SizedBox(height: 10),
                const Text('댓글', style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 16, backgroundColor: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['author'] ?? '익명',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text(c['content'] ?? '',
                                      style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: '댓글을 입력하세요...',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.black54,
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                      isPostingComment
                          ? const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: () async {
                                await _postComment();
                                Navigator.pop(context);
                                _showCommentSheet(); // 새로고침
                              },
                            ),
                    ],
                  ),
                )
              ],
            );
          },
        ),
      );
    },
  );
}

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Widget iconWithBg(IconData icon, {double size = 28}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nickname = widget.post['authorNickname'] ?? '';
    final profileImg = widget.post['authorProfileImg'] ?? '';
    final content = widget.post['content'] ?? '';
    final profileUrl = profileImg.isNotEmpty
        ? 'http://192.168.0.53:8080/api/posts/image?filename=${Uri.encodeComponent(profileImg.split('/').last)}'
        : '';

    return Stack(
      children: [
        if (_controller.value.isInitialized)
          Center(child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)))
        else
          const Center(child: CircularProgressIndicator()),
        Positioned(
          top: 40,
          left: 10,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/index', (route) => false),
            child: iconWithBg(Icons.arrow_back),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: iconWithBg(isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart, size: 32),
              ),
              Text('$likeCount', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showCommentSheet,
                child: iconWithBg(FontAwesomeIcons.commentDots),
              ),
              Text('${comments.length}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              iconWithBg(FontAwesomeIcons.shareNodes, size: 26),
              const Text('공유', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              iconWithBg(FontAwesomeIcons.flag, size: 24),
              const Text('신고', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        Positioned(
          left: 16,
          bottom: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage: profileUrl.isNotEmpty
                    ? NetworkImage(profileUrl)
                    : const AssetImage('assets/Screenshot_20250625_034855_KakaoStory1.jpg') as ImageProvider,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$nickname', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(content, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}