package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.entity.InquiryEntity;
import com.group3.askmyfriend.service.UserService;
import com.group3.askmyfriend.service.InquiryService;
import com.group3.askmyfriend.service.CustomUserDetailsService.CustomUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/setting")
@RequiredArgsConstructor
public class SettingRestController {

    private final UserService userService;
    private final InquiryService inquiryService;

    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal CustomUser user
    ) {
        String current = body.get("currentPassword");
        String neu     = body.get("newPassword");
        String conf    = body.get("confirmPassword");

        try {
            Long userId = userService.findByLoginId(user.getUsername())
                                     .orElseThrow(() -> new IllegalArgumentException("사용자 정보가 없습니다."))
                                     .getUserId();

            userService.changePassword(userId, current, neu, conf);
            return ResponseEntity.ok(Map.of("message", "비밀번호가 변경되었습니다."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/verify-password")
    public ResponseEntity<Map<String, String>> verifyPassword(
            @AuthenticationPrincipal CustomUser user,
            @RequestBody Map<String, String> body
    ) {
        String password = body.get("password");
        try {
            userService.validateLogin(user.getUsername(), password);
            return ResponseEntity.ok(Map.of("result", "ok"));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "비밀번호가 일치하지 않습니다."));
        }
    }

    @PostMapping("/change-phone")
    public ResponseEntity<Map<String, String>> changePhone(
            @AuthenticationPrincipal CustomUser user,
            @RequestBody Map<String, String> body
    ) {
        String newPhone = body.get("newPhone");
        userService.findByLoginId(user.getUsername())
                   .ifPresent(u -> userService.updatePhone(u.getUserId(), newPhone));
        return ResponseEntity.ok(Map.of("result", "ok"));
    }

    @PostMapping("/send-inquiry")
    public ResponseEntity<?> sendInquiry(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal CustomUser user
    ) {
        String title = body.get("title");
        String content = body.get("content");

        if (title == null || title.trim().isEmpty() || content == null || content.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "제목과 내용을 모두 입력하세요."));
        }

        try {
            Long userId = userService.findByLoginId(user.getUsername())
                                     .orElseThrow(() -> new IllegalArgumentException("사용자 정보가 없습니다."))
                                     .getUserId();

            InquiryEntity inquiry = InquiryEntity.builder()
                    .userId(userId)
                    .title(title)
                    .content(content)
                    .createdAt(LocalDateTime.now())
                    .build();

            inquiryService.submitInquiry(inquiry);
            return ResponseEntity.ok(Map.of("result", "ok"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * 5) 모바일: 내 1:1 문의 목록 조회
     *    응답: List<InquiryEntity> (필요 시 DTO로 변환 가능)
     */
    @GetMapping("/my-inquiries")
    public ResponseEntity<List<InquiryEntity>> getMyInquiries(
            @AuthenticationPrincipal CustomUser user
    ) {
        Long userId = user.getId();
        List<InquiryEntity> list = inquiryService.getUserInquiries(userId);
        return ResponseEntity.ok(list);
    }
}
