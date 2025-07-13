// lib/pages/post_show_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'post_detail_page.dart';

const String baseUrl = 'http://192.168.0.53:8080';

class PostShowPage extends StatefulWidget {
  const PostShowPage({super.key});

  @override
  State<PostShowPage> createState() => _PostShowPageState();
}

class _PostShowPageState extends State<PostShowPage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('$baseUrl/api/posts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonList = json.decode(response.body) as List<dynamic>;
      setState(() {
        posts = jsonList;
        isLoading = false;
      });
    } else {
      print('Failed to load posts: ${response.statusCode}');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("맞팔로우 피드"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/index'),
        ),
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index] as Map<String, dynamic>;
                return PostCard(post: post);
              },
            ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int likeCount;
  late bool isLiked;
  bool isToggling = false;

  @override
  void initState() {
    super.initState();
    // 서버에서 내려준 likeCount를 파싱
    likeCount = int.tryParse(widget.post['likeCount'].toString()) ?? 0;
    // 서버에서 내려준 likedByMe 값을 초기화
    isLiked = widget.post['likedByMe'] == true;
  }

  Future<void> _toggleLike() async {
    if (isToggling) return;
    setState(() => isToggling = true);

    final token = await const FlutterSecureStorage().read(key: 'jwt');
    if (token == null) {
      setState(() => isToggling = false);
      return;
    }

    final postId = widget.post['id'];
    final uri = Uri.parse('$baseUrl/api/posts/$postId/like');
    late http.Response res;

    if (!isLiked) {
      // 좋아요 등록
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
      // 좋아요 취소
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

    setState(() => isToggling = false);
  }

  String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('/uploads/')) {
      final filename = Uri.encodeComponent(path.split('/').last);
      return '$baseUrl/api/posts/image?filename=$filename';
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
    final postId     = widget.post['id'];
    final imagePaths = widget.post['imagePaths'] as List<dynamic>? ?? [];
    final rawVideo   = widget.post['videoPath'] as String?;
    final videoPath  = resolveUrl(rawVideo);
    final profileUrl = resolveUrl(widget.post['authorProfileImg'] as String?);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailPage(postId: postId)),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 작성자 & 시간
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.post['authorNickname'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    formatTime(widget.post['formattedTime'] ?? ''),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              // 본문
              Text(
                widget.post['content'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 12),
              // 이미지 리스트
              if (imagePaths.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagePaths.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (_, i) {
                      final url = resolveUrl(imagePaths[i].toString());
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

              // 비디오
              if (videoPath.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: VideoWidget(videoUrl: videoPath),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              // 좋아요 & 댓글
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.black54,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text('$likeCount'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.comment,
                      size: 20,
                      color: Colors.black54,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailPage(postId: postId),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('${widget.post['commentCount'] ?? 0}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoWidget extends StatefulWidget {
  final String videoUrl;
  const VideoWidget({super.key, required this.videoUrl});

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
      return const Center(
        child: Text('영상 재생 오류', style: TextStyle(color: Colors.red)),
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
