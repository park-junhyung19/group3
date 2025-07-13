// lib/pages/post_detail_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const String baseUrl = 'http://192.168.0.53:8080';

class PostDetailPage extends StatefulWidget {
  final int postId;
  const PostDetailPage({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _storage = const FlutterSecureStorage();
  final _commentController = TextEditingController();

  Map<String, dynamic>? post;
  bool isLoading = true;
  bool isPostingComment = false;

  // 좋아요 상태
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) return;

    final res = await http.get(
      Uri.parse('$baseUrl/api/posts/${widget.postId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      // 숫자 변환
      data['likeCount'] = int.tryParse(data['likeCount'].toString()) ?? 0;
      data['commentCount'] = int.tryParse(data['commentCount'].toString()) ?? 0;

      setState(() {
        post = data;
        likeCount = data['likeCount'];
        isLiked = data['likedByMe'] == true;
        isLoading = false;
      });
    } else {
      print('Detail load failed: ${res.statusCode}');
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleLike() async {
    if (post == null) return;
    final token = await _storage.read(key: 'jwt');
    if (token == null) return;

    final uri = Uri.parse('$baseUrl/api/posts/${widget.postId}/like');
    http.Response res;

    if (!isLiked) {
      res = await http.post(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (res.statusCode == 200) {
        setState(() {
          isLiked = true;
          likeCount += 1;
        });
      }
    } else {
      res = await http.delete(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (res.statusCode == 200) {
        setState(() {
          isLiked = false;
          likeCount = likeCount > 0 ? likeCount - 1 : 0;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => isPostingComment = true);
    final token = await _storage.read(key: 'jwt');
    final res = await http.post(
      Uri.parse('$baseUrl/api/posts/${widget.postId}/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': text}),
    );
    if (res.statusCode == 201) {
      _commentController.clear();
      await _fetchDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 등록 실패 (${res.statusCode})')),
      );
    }
    setState(() => isPostingComment = false);
  }

  String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('/uploads/')) {
      final fn = Uri.encodeComponent(path.split('/').last);
      return '$baseUrl/api/posts/image?filename=$fn';
    }
    return path;
  }

  String formatTime(String isoTime) {
    try {
      final created = DateTime.parse(isoTime).toLocal();
      final now = DateTime.now();
      final diff = now.difference(created);
      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inHours < 1) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentCount = post?['commentCount'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Detail')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : post == null
              ? const Center(child: Text('Failed to load'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author & Time
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage:
                                      resolveUrl(post!['authorProfileImg'] as String?).isNotEmpty
                                          ? NetworkImage(resolveUrl(post!['authorProfileImg'] as String?))
                                          : null,
                                  child: resolveUrl(post!['authorProfileImg'] as String?).isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  post!['authorNickname'] as String? ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Spacer(),
                                Text(
                                  formatTime(post!['createdAt'] as String),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Content
                            Text(
                              post!['content'] as String? ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),

                            // Images
                            if ((post!['imagePaths'] as List).isNotEmpty)
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: (post!['imagePaths'] as List).length,
                                  itemBuilder: (c, i) {
                                    final url = resolveUrl(
                                        (post!['imagePaths'] as List)[i] as String);
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          url,
                                          width: 200,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Video
                            if ((post!['videoPath'] as String?)?.isNotEmpty ?? false)
                              ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: VideoWidget(
                                      videoUrl: resolveUrl(post!['videoPath'] as String),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                            // Like & Comment counts (match icon sizes)
                            Row(
                              children: [
                                IconButton(
                                  icon: FaIcon(
                                    isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                                    size: 20,
                                    color: isLiked ? Colors.red : Colors.black54,
                                  ),
                                  onPressed: _toggleLike,
                                ),
                                const SizedBox(width: 4),
                                Text('$likeCount'),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: FaIcon(
                                    FontAwesomeIcons.comment,
                                    size: 20,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {}, // no-op
                                ),
                                const SizedBox(width: 4),
                                Text('$commentCount'),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Comments...
                            if ((post!['comments'] as List).isNotEmpty)
                              ...[
                                const Text(
                                  '댓글',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ...(post!['comments'] as List).map<Widget>((cm) {
                                  final rawCmProfile =
                                      cm['authorProfileImg'] as String?;
                                  final cmAvatarUrl = resolveUrl(rawCmProfile);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundImage: cmAvatarUrl.isNotEmpty
                                              ? NetworkImage(cmAvatarUrl)
                                              : null,
                                          child: cmAvatarUrl.isEmpty
                                              ? Text(
                                                  (cm['author'] as String)
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cm['author'] as String? ?? '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(cm['content'] as String? ?? ''),
                                              const SizedBox(height: 4),
                                              Text(
                                                formatTime(cm['createdAt'] as String),
                                                style: const TextStyle(
                                                    fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                          ],
                        ),
                      ),
                    ),

                    // Comment input
                    SafeArea(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: '댓글을 입력하세요.',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF0F0F0),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.send,
                                color: isPostingComment ? Colors.grey : Colors.blue,
                              ),
                              onPressed: isPostingComment ? null : _submitComment,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class VideoWidget extends StatefulWidget {
  final String videoUrl;
  const VideoWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.setVolume(1.0);
      }).catchError((e) => print("Video init error: $e"));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.hasError) {
      return Text(
        'Error: ${_controller.value.errorDescription}',
        style: const TextStyle(color: Colors.red),
      );
    }
    return _controller.value.isInitialized
        ? Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  size: 48,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
            ],
          )
        : const Center(child: CircularProgressIndicator());
  }
}
