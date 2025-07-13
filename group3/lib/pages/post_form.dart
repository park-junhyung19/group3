import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PostFormScreen extends StatefulWidget {
  const PostFormScreen({super.key});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final TextEditingController _contentController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _selectedImages = [];
  XFile? _selectedVideo;

  bool _isShortForm = false;
  bool _isSending = false;

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('사진 여러 장 선택'),
              onTap: () async {
                Navigator.pop(context);
                final images = await _picker.pickMultiImage();
                if (images.length + _selectedImages.length > 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('최대 10장까지 업로드할 수 있습니다.')),
                  );
                  return;
                }
                setState(() => _selectedImages.addAll(images));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null && _selectedImages.length < 10) {
                  setState(() => _selectedImages.add(image));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('최대 10장까지 업로드할 수 있습니다.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _selectedVideo = video);
    }
  }

  Future<void> _sendPost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력하세요.')),
      );
      return;
    }

    setState(() => _isSending = true);

    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      setState(() => _isSending = false);
      return;
    }

    final uri = Uri.parse('http://192.168.0.53:8080/api/posts/upload-multiple');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['content'] = content
      ..fields['visibility'] = 'PUBLIC'
      ..fields['shortForm'] = _isShortForm.toString();

    for (final image in _selectedImages) {
      request.files.add(await http.MultipartFile.fromPath('images', image.path));
    }

    if (_selectedVideo != null) {
      request.files.add(await http.MultipartFile.fromPath('video', _selectedVideo!.path));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text('업로드 완료'),
              content: const Text('게시글이 등록되었습니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pushNamedAndRemoveUntil(context, '/index', (_) => false);
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전송 실패: ${response.statusCode}\n${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/index', (_) => false);
          },
        ),
        title: const Text('친구공개', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _sendPost,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple),
                  )
                : const Text('올리기', style: TextStyle(color: Colors.purple)),
          ),
        ],
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('오늘 하루, 어떤 일이 있었나요?', style: TextStyle(color: Colors.black87)),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '내용을 입력하세요...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._selectedImages.map((img) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _imageCard(img),
                      )),
                  _addImageButton(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedVideo != null)
              Text("🎞️ 선택된 영상: ${_selectedVideo!.name}", style: const TextStyle(color: Colors.black87)),
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_library),
              label: const Text("영상 선택하기"),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('숏폼으로 업로드'),
              value: _isShortForm,
              onChanged: (value) {
                setState(() => _isShortForm = value);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.camera_alt, color: Colors.black54), onPressed: _showImageSourceDialog),
            IconButton(icon: const Icon(Icons.video_call, color: Colors.black54), onPressed: _pickVideo),
            IconButton(icon: const Icon(Icons.emoji_emotions, color: Colors.black54), onPressed: () {}),
            IconButton(icon: const Icon(Icons.tag, color: Colors.black54), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _imageCard(XFile image) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(image.path),
            width: 120,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _selectedImages.remove(image)),
            child: const Icon(Icons.close, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _addImageButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.black54, size: 40),
        ),
      ),
    );
  }
}
