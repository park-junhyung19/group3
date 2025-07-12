package com.group3.askmyfriend.controller;

import java.security.Principal;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.group3.askmyfriend.dto.PostDto;
import com.group3.askmyfriend.entity.PostEntity;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.FollowRepository;
import com.group3.askmyfriend.service.PostService;
import com.group3.askmyfriend.service.UserService;

@Controller
public class MainController {

    @Autowired private PostService postService;
    @Autowired private UserService userService;
    @Autowired private FollowRepository followRepository; // 🔁 친구 정보도 가져올 수 있도록 추가

    // /index → index.html
    @GetMapping("/index")
    public String index(Principal principal, Model model) {
        List<PostDto> posts = postService.findAllPostDtos(Sort.by(Sort.Direction.DESC, "createdAt"));
        UserEntity user = userService.findByLoginId(principal.getName()).orElse(null);
        model.addAttribute("posts", posts);
        model.addAttribute("user", user);
        return "index";
    }

    // / → /index로 리다이렉트
    @GetMapping("/")
    public String homeRedirect() {
        return "redirect:/index";
    }

    // ✅ /friends → friends.html로 연결
    @GetMapping("/friends")
    public String friendsPage(Principal principal, Model model) {
        if (principal == null) return "redirect:/auth/login";

        String loginId = principal.getName();
        UserEntity currentUser = userService.findByLoginId(loginId).orElse(null);

        if (currentUser != null) {
            model.addAttribute("currentUser", currentUser);
            model.addAttribute("followingList", followRepository.findFollowingByFollower(currentUser));
            model.addAttribute("followerList", followRepository.findFollowersByFollowing(currentUser));
        }

        return "friends"; // → templates/friends.html
    }
}
