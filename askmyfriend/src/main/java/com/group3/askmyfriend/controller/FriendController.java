package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.dto.MypageDto;
import com.group3.askmyfriend.entity.PostEntity;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.FollowRepository;
import com.group3.askmyfriend.repository.UserRepository;
import com.group3.askmyfriend.service.MypageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;

import java.security.Principal;
import java.util.ArrayList;
import java.util.List;

@Controller
@RequestMapping("/friend-management")
public class FriendController {

    private final UserRepository userRepository;
    private final FollowRepository followRepository;
    private final MypageService mypageService;

    @Autowired
    public FriendController(UserRepository userRepository,
                            FollowRepository followRepository,
                            MypageService mypageService) {
        this.userRepository = userRepository;
        this.followRepository = followRepository;
        this.mypageService = mypageService;
    }

    // ⭐️ 친구 페이지로 이동 (비공개 계정 처리 수정)
    @GetMapping("/profile/{loginId}")
    public String viewFriendProfile(@PathVariable String loginId,
                                    Model model,
                                    Principal principal) {
        try {
            // 1) 친구 정보 조회
            UserEntity friendUser = userRepository.findByLoginId(loginId).orElse(null);
            if (friendUser == null) {
                return "redirect:/friend-management";
            }

            // 2) 현재 사용자 & 소유권/팔로우 여부
            UserEntity currentUser = null;
            boolean isOwner = false;
            boolean isFollowing = false;
            if (principal != null) {
                String currentLoginId = principal.getName();
                isOwner = currentLoginId.equals(loginId);
                currentUser = userRepository.findByLoginId(currentLoginId).orElse(null);
                if (!isOwner && currentUser != null) {
                    isFollowing = followRepository.existsByFollowerAndFollowing(currentUser, friendUser);
                }
            }

            // 3) 공개 범위 체크
            boolean isPrivate = "private".equalsIgnoreCase(friendUser.getPrivacy());
            if (isPrivate && !isOwner && !isFollowing) {
                // 비공개 계정 정보만 전달
                MypageDto privateAccountInfo = new MypageDto(
                    friendUser.getLoginId(),
                    friendUser.getNickname(),
                    friendUser.getLoginId(),
                    friendUser.getBio() != null ? friendUser.getBio() : "비공개 계정입니다.",
                    friendUser.getProfileImg() != null ? friendUser.getProfileImg() : "/img/profile_default.jpg",
                    friendUser.getBackgroundImg() != null ? friendUser.getBackgroundImg() : "/img/cover_default.jpg",
                    0, 0,
                    friendUser.getCreatedDate(),
                    "private"
                );
                model.addAttribute("user", privateAccountInfo);
                model.addAttribute("isOwner", false);
                model.addAttribute("isFollowing", isFollowing);
                return "mypage_private";
            }

            // 4) 전체 정보 표시
            MypageDto friendInfo = mypageService.getMypageInfo(loginId);
            List<PostEntity> friendPosts = mypageService.getMyPosts(loginId);
            List<PostEntity> friendMedia = mypageService.getMyMediaList(loginId);

            model.addAttribute("user", friendInfo);
            model.addAttribute("posts", friendPosts);
            model.addAttribute("mediaList", friendMedia);
            model.addAttribute("replyList", new ArrayList<>());
            model.addAttribute("likePosts", new ArrayList<>());
            model.addAttribute("isOwner", isOwner);
            model.addAttribute("isFollowing", isFollowing);
            model.addAttribute("isPrivateAccount", false);
            return "mypage";
        } catch (Exception e) {
            e.printStackTrace();
            return "redirect:/friend-management";
        }
    }

    // ⭐️ 친구 페이지로 이동 (userId 기반) - 호환성을 위해 추가
    @GetMapping("/profile/user/{userId}")
    public String viewFriendProfileByUserId(@PathVariable Long userId,
                                            Model model,
                                            Principal principal) {
        try {
            UserEntity friendUser = userRepository.findByUserId(userId).orElse(null);
            if (friendUser == null) {
                return "redirect:/friend-management";
            }
            return "redirect:/friend-management/profile/" + friendUser.getLoginId();
        } catch (Exception e) {
            e.printStackTrace();
            return "redirect:/friend-management";
        }
    }
}
