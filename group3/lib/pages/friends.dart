import 'package:flutter/material.dart';

// 친구 데이터 모델
class Friend {
  final int userId;
  final String nickname;
  final String loginId;
  final String statusMessage;
  final String profileImageUrl;
  final bool isFollowing;
  final bool isMutual;

  Friend({
    required this.userId,
    required this.nickname,
    required this.loginId,
    this.statusMessage = '',
    this.profileImageUrl = '',
    this.isFollowing = false,
    this.isMutual = false,
  });
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // 더미 데이터 (API 연동시 교체)
  List<Friend> following = [
    Friend(userId: 1, nickname: 'saguming1', loginId: 'saguming1', isFollowing: true),
    Friend(userId: 2, nickname: 'saguming11', loginId: 'saguming11', isFollowing: true),
  ];
  List<Friend> followers = [
    Friend(userId: 3, nickname: '접니다 저', loginId: 'saguming12', statusMessage: '저예요', isMutual: true),
    Friend(userId: 4, nickname: 'saguming100', loginId: 'saguming100'),
  ];
  List<Friend> searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _searchController.clear();
        searchResults.clear();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // 실제 API 연동 시 서버에서 검색
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
      });
      return;
    }
    setState(() {
      searchResults = [
        Friend(userId: 100, nickname: query, loginId: query),
      ];
    });
  }

  Widget _buildFriendCard(Friend friend, String tab) {
    final bool isFollowing = friend.isFollowing || tab == '팔로잉';
    final bool isMutual = friend.isMutual;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: friend.profileImageUrl.isNotEmpty
            ? NetworkImage(friend.profileImageUrl)
            : null,
        backgroundColor: Colors.grey[200],
        child: friend.profileImageUrl.isEmpty
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Text(friend.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('@${friend.loginId}', style: const TextStyle(color: Colors.black54, fontSize: 14)),
          if (friend.statusMessage.isNotEmpty)
            Text(friend.statusMessage, style: const TextStyle(color: Colors.black45, fontSize: 13)),
        ],
      ),
      trailing: tab == '팔로잉'
          ? _buildFollowButton(isFollowing: true, label: '팔로잉', onPressed: () {
              setState(() {
                following.removeWhere((f) => f.userId == friend.userId);
              });
            })
          : tab == '팔로워'
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusChip('나를 팔로우', Colors.grey[200]!, Colors.black54),
                    const SizedBox(width: 6),
                    _buildFollowButton(
                      isFollowing: isMutual,
                      label: '맞팔로우',
                      onPressed: () {
                        setState(() {
                          followers = followers.map((f) => f.userId == friend.userId
                              ? Friend(
                                  userId: f.userId,
                                  nickname: f.nickname,
                                  loginId: f.loginId,
                                  statusMessage: f.statusMessage,
                                  profileImageUrl: f.profileImageUrl,
                                  isFollowing: !isMutual,
                                  isMutual: !isMutual,
                                )
                              : f).toList();
                        });
                      },
                    ),
                  ],
                )
              : _buildFollowButton(
                  isFollowing: friend.isFollowing,
                  label: friend.isFollowing ? '팔로잉' : '팔로우',
                  onPressed: () {
                    setState(() {
                      if (friend.isFollowing) {
                        searchResults = searchResults.map((f) => f.userId == friend.userId
                            ? Friend(
                                userId: f.userId,
                                nickname: f.nickname,
                                loginId: f.loginId,
                                statusMessage: f.statusMessage,
                                profileImageUrl: f.profileImageUrl,
                                isFollowing: false,
                              )
                            : f).toList();
                      } else {
                        searchResults = searchResults.map((f) => f.userId == friend.userId
                            ? Friend(
                                userId: f.userId,
                                nickname: f.nickname,
                                loginId: f.loginId,
                                statusMessage: f.statusMessage,
                                profileImageUrl: f.profileImageUrl,
                                isFollowing: true,
                              )
                            : f).toList();
                      }
                    });
                  },
                ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minVerticalPadding: 10,
    );
  }

  Widget _buildFollowButton({
    required bool isFollowing,
    required VoidCallback onPressed,
    required String label,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing ? const Color(0xFF8e44ad) : Colors.white,
        foregroundColor: isFollowing ? Colors.white : const Color(0xFF8e44ad),
        side: BorderSide(color: const Color(0xFF8e44ad)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildStatusChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tabController.index == 0
        ? '유저검색'
        : _tabController.index == 1
            ? '팔로잉'
            : '팔로워';

    List<Friend> currentList;
    if (tab == '유저검색') {
      currentList = searchResults;
    } else if (tab == '팔로잉') {
      currentList = following;
    } else {
      currentList = followers;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/index', (route) => false);
          },
        ),
        title: const Text('친구 관리', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF8e44ad),
              labelColor: const Color(0xFF8e44ad),
              unselectedLabelColor: Colors.black45,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              tabs: const [
                Tab(text: '유저검색'),
                Tab(text: '팔로잉'),
                Tab(text: '팔로워'),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: _tabController.index == 0 ? _onSearchChanged : null,
              enabled: _tabController.index == 0,
              decoration: InputDecoration(
                hintText: '사용자 검색...',
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          Expanded(
            child: currentList.isEmpty
                ? const Center(
                    child: Text(
                      '이 목록에는 아직 사용자가 없습니다.',
                      style: TextStyle(color: Colors.black38, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: currentList.length,
                    itemBuilder: (context, idx) => _buildFriendCard(currentList[idx], tab),
                  ),
          ),
        ],
      ),
    );
  }
}
