package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.dto.MypageDto;
import com.group3.askmyfriend.dto.UserSummaryDTO;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.UserRepository;
import com.group3.askmyfriend.service.FollowService;
import com.group3.askmyfriend.service.MypageService;
import com.group3.askmyfriend.service.CustomUserDetailsService.CustomUser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/follow")
public class FollowController {

    private final FollowService followService;
    private final UserRepository userRepository;
    private final MypageService mypageService;

    @Autowired
    public FollowController(
            FollowService followService,
            UserRepository userRepository,
            MypageService mypageService) {
        this.followService = followService;
        this.userRepository = userRepository;
        this.mypageService = mypageService;
    }

    // 1) ID 기준 팔로우
    @PostMapping("/{targetUserId}")
    public ResponseEntity<Void> follow(
            @PathVariable Long targetUserId,
            @AuthenticationPrincipal CustomUser user) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        followService.follow(user, targetUserId);
        return ResponseEntity.ok().build();
    }

    // 2) ID 기준 언팔로우
    @DeleteMapping("/{targetUserId}")
    public ResponseEntity<Void> unfollow(
            @PathVariable Long targetUserId,
            @AuthenticationPrincipal CustomUser user) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        followService.unfollow(user, targetUserId);
        return ResponseEntity.ok().build();
    }

    // 3) 로그인ID 기준 팔로우
    @PostMapping("/by-login/{loginId}")
    public ResponseEntity<Void> followByLogin(
            @PathVariable String loginId,
            @AuthenticationPrincipal CustomUser user) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        UserEntity target = userRepository.findByLoginId(loginId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + loginId));
        followService.follow(user, target.getUserId());
        return ResponseEntity.ok().build();
    }

    // 4) 로그인ID 기준 언팔로우
    @DeleteMapping("/by-login/{loginId}")
    public ResponseEntity<Void> unfollowByLogin(
            @PathVariable String loginId,
            @AuthenticationPrincipal CustomUser user) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        UserEntity target = userRepository.findByLoginId(loginId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + loginId));
        followService.unfollow(user, target.getUserId());
        return ResponseEntity.ok().build();
    }

    // 5) 내가 이 사용자를 팔로우 중인지
    @GetMapping("/status-by-login/{loginId}")
    public ResponseEntity<Boolean> getFollowStatusByLogin(
            @PathVariable String loginId,
            @AuthenticationPrincipal CustomUser user) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(false);
        }
        UserEntity target = userRepository.findByLoginId(loginId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + loginId));
        return ResponseEntity.ok(followService.isFollowing(user, target.getUserId()));
    }

    // 6) 팔로잉 목록 (UserSummaryDTO)
    @GetMapping("/following")
    public ResponseEntity<List<UserSummaryDTO>> getFollowing(
            @AuthenticationPrincipal CustomUser user) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(followService.getFollowing(user));
    }

    // 7) 팔로워 목록 (UserSummaryDTO)
    @GetMapping("/followers")
    public ResponseEntity<List<UserSummaryDTO>> getFollowers(
            @AuthenticationPrincipal CustomUser user) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(followService.getFollowers(user));
    }

    // 8) 닉네임 검색 (최대 10명, 본인 제외)
    @GetMapping("/search")
    public ResponseEntity<List<UserEntity>> searchUsers(
            @RequestParam String query,
            @AuthenticationPrincipal CustomUser user) {
        if (user == null) {
            return ResponseEntity.ok(new ArrayList<>());
        }
        List<UserEntity> results = userRepository.findByNicknameContainingIgnoreCase(query)
                .stream()
                .filter(u -> !u.getLoginId().equals(user.getUsername()))
                .limit(10)
                .collect(Collectors.toList());
        return ResponseEntity.ok(results);
    }

    // 9) 상호 팔로우 여부
    @GetMapping("/mutual/{otherUserId}")
    public ResponseEntity<Boolean> isMutual(
            @PathVariable Long otherUserId,
            @AuthenticationPrincipal CustomUser user) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(false);
        }
        return ResponseEntity.ok(followService.isMutualFollow(user, otherUserId));
    }

    // 10) 내가 otherUserId 팔로우 중인지
    @GetMapping("/isFollowing/{otherUserId}")
    public ResponseEntity<Boolean> isFollowing(
            @PathVariable Long otherUserId,
            @AuthenticationPrincipal CustomUser user) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(false);
        }
        return ResponseEntity.ok(followService.isFollowing(user, otherUserId));
    }

    /**
     * 11) 상대 프로필 조회
     *    공개/비공개 여부에 따라 요약 DTO 또는 전체 정보 DTO 반환
     */
    @GetMapping("/profile/{loginId}")
    public ResponseEntity<MypageDto> getProfile(
            @PathVariable String loginId,
            @AuthenticationPrincipal CustomUser user) {

        UserEntity target = userRepository.findByLoginId(loginId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + loginId));

        boolean isOwner = (user != null && user.getUsername().equals(loginId));
        boolean isFollowing = (user != null && !isOwner)
                && followService.isFollowing(user, target.getUserId());

        boolean isPrivate = "private".equalsIgnoreCase(target.getPrivacy());
        MypageDto dto;
        if (isPrivate && !isOwner && !isFollowing) {
            // 비공개 계정이면 요약 정보
            dto = new MypageDto(
                target.getLoginId(),
                target.getNickname(),
                target.getLoginId(),
                target.getBio() != null ? target.getBio() : "비공개 계정입니다.",
                target.getProfileImg() != null ? target.getProfileImg() : "/img/profile_default.jpg",
                target.getBackgroundImg() != null ? target.getBackgroundImg() : "/img/cover_default.jpg",
                0, 0,
                target.getCreatedDate(),
                "private"
            );
        } else {
            // 전체 정보
            dto = mypageService.getMypageInfo(loginId);
        }

        return ResponseEntity.ok(dto);
    }
}
