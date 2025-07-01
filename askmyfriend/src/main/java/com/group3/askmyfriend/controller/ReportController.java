package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.dto.ReportRequestDto;
import com.group3.askmyfriend.dto.ChatReportRequestDto;
import com.group3.askmyfriend.entity.ReportEntity;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.service.ReportService;
import com.group3.askmyfriend.service.ChatReportService;
import com.group3.askmyfriend.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/reports")
public class ReportController {
    private final ReportService service;
    
    @Autowired
    private ChatReportService chatReportService;
    
    @Autowired
    private UserService userService;

    public ReportController(ReportService service) {
        this.service = service;
    }

    /**
     * 사용자 신고 등록 (기존 게시글/댓글 신고)
     */
    @PostMapping
    public ResponseEntity<Void> createReport(@RequestBody ReportRequestDto dto) {
        Long id = service.save(dto);
        return ResponseEntity.created(URI.create("/reports/" + id)).build();
    }

    /**
     * 채팅 메시지 신고 등록 (Optional 처리 수정)
     */
    @PostMapping("/chat")
    public ResponseEntity<String> createChatReport(@RequestBody ChatReportRequestDto dto) {
        try {
            System.out.println("채팅 신고 요청 받음: messageId=" + dto.getMessageId() + ", reason=" + dto.getReason());
            
            // Spring Security에서 현재 인증된 사용자 정보 가져오기
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            
            if (authentication == null || !authentication.isAuthenticated() || 
                authentication.getName().equals("anonymousUser")) {
                System.err.println("인증되지 않은 사용자의 신고 시도");
                return ResponseEntity.status(401).body("로그인이 필요합니다.");
            }
            
            // 인증된 사용자의 로그인 ID (username) 가져오기
            String loginId = authentication.getName();
            System.out.println("인증된 사용자 로그인 ID: " + loginId);
            
            // 로그인 ID로 UserEntity 조회 (Optional 처리)
            Optional<UserEntity> userOptional = userService.findByLoginId(loginId);
            
            if (!userOptional.isPresent()) {
                System.err.println("사용자 정보를 찾을 수 없음: " + loginId);
                return ResponseEntity.status(500).body("사용자 정보를 찾을 수 없습니다.");
            }
            
            UserEntity currentUser = userOptional.get();
            Long currentUserId = currentUser.getUserId();
            System.out.println("신고자 ID: " + currentUserId);
            
            // 채팅 신고 처리
            chatReportService.reportMessage(dto, currentUserId);
            
            System.out.println("채팅 신고 처리 완료");
            return ResponseEntity.ok("신고가 접수되었습니다.");
            
        } catch (Exception e) {
            System.err.println("채팅 신고 처리 오류: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.badRequest().body("신고 처리 중 오류가 발생했습니다: " + e.getMessage());
        }
    }

    /**
     * 관리자 전용: 신고 상태 변경
     */
    @PatchMapping("/{id}")
    public ResponseEntity<Void> updateStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        ReportEntity.Status newStatus = ReportEntity.Status.valueOf(body.get("status"));
        service.updateStatus(id, newStatus);
        return ResponseEntity.noContent().build();
    }
}
