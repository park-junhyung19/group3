package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.UserRepository;
import com.group3.askmyfriend.service.LikeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/likes")
public class LikeProxyController {

    private final LikeService likeService;
    private final UserRepository userRepository;

    public LikeProxyController(LikeService likeService, UserRepository userRepository) {
        this.likeService = likeService;
        this.userRepository = userRepository;
    }

    /**
     * Flutter 전용 프록시 좋아요 API
     * POST /api/likes/{postId}?userEmail=saguming (← loginId일 수도 있음)
     */
    @PostMapping("/{postId}")
    public ResponseEntity<Integer> proxyLike(
            @PathVariable Long postId,
            @RequestParam String userEmail
    ) {
        // ✅ email이 아니라 loginId가 들어왔을 수도 있으므로 체크
        String resolvedEmail = userRepository.findByEmail(userEmail).isPresent()
                ? userEmail
                : userRepository.findByLoginId(userEmail)
                    .map(UserEntity::getEmail)
                    .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + userEmail));

        int likeCount = likeService.toggleLike(postId, resolvedEmail);
        return ResponseEntity.ok(likeCount);
    }
}
