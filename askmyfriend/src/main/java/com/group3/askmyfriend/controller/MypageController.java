package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.dto.MypageDto;
import com.group3.askmyfriend.entity.PostEntity;
import com.group3.askmyfriend.repository.FollowRepository;
import com.group3.askmyfriend.repository.UserRepository;
import com.group3.askmyfriend.service.MypageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.security.Principal;
import java.util.List;

@Controller
@RequestMapping("/mypage")
public class MypageController {

    @Autowired
    private MypageService mypageService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FollowRepository followRepository;

    /**
     * 본인 마이페이지 요청 → user/{loginId}로 포워드
     */
    @GetMapping
    public String mypage(Principal principal) {
        if (principal == null) {
            return "redirect:/auth/login";
        }
        return "forward:/mypage/user/" + principal.getName();
    }

    /**
     * 타인 및 본인 마이페이지 GET 요청
     */
    @GetMapping("/user/{userId}")
    public String showUserPage(
            @PathVariable("userId") String userId,
            Principal principal,
            Model model
    ) {
        // 사용자 기본 정보 조회
        MypageDto targetUser = mypageService.getMypageInfo(userId);
        model.addAttribute("user", targetUser);

        // 본인 여부 확인
        boolean isOwner = principal != null && principal.getName().equals(userId);
        model.addAttribute("isOwner", isOwner);

        // 탭별 데이터 조회
        List<PostEntity> posts     = mypageService.getMyPosts(userId);
        List<PostEntity> replyList = mypageService.getMyRepliedPosts(userId);
        List<PostEntity> likePosts = mypageService.getMyLikedPosts(userId);
        List<PostEntity> mediaList = mypageService.getMyMediaList(userId);

        model.addAttribute("posts",     posts);
        model.addAttribute("replyList", replyList);
        model.addAttribute("likePosts", likePosts);
        model.addAttribute("mediaList", mediaList);

        return "mypage";
    }

    /**
     * 프로필 수정 POST 요청
     */
    @PostMapping("/updateProfile")
    public String updateProfile(
            @RequestParam(value = "backgroundImg", required = false) MultipartFile backgroundImg,
            @RequestParam(value = "profileImg", required = false) MultipartFile profileImg,
            @RequestParam("username") String nickname,
            @RequestParam("bio") String bio,
            @RequestParam(value = "privacy", required = false) String privacy,
            Principal principal) {
        if (principal == null) {
            return "redirect:/auth/login";
        }

        mypageService.updateProfile(principal.getName(), backgroundImg, profileImg, nickname, bio, privacy);
        return "redirect:/mypage";
    }
}
