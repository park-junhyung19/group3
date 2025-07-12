package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.dto.ChatMessageDTO;
import com.group3.askmyfriend.entity.AdminEntity;
import com.group3.askmyfriend.entity.ChatReport;
import com.group3.askmyfriend.entity.InquiryEntity;
import com.group3.askmyfriend.entity.ReportEntity;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.AdminRepository;
import com.group3.askmyfriend.repository.ChatReportRepository;
import com.group3.askmyfriend.repository.ReportRepository;
import com.group3.askmyfriend.repository.UserRepository;
import com.group3.askmyfriend.service.AdminService;
import com.group3.askmyfriend.service.ChatService;
import com.group3.askmyfriend.service.InquiryService;
import com.group3.askmyfriend.service.ReportService;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")  // 개발 중에는 모든 출처 허용, 배포 전에는 제한하세요
@RequiredArgsConstructor
public class AdminRestController {

    private final AdminService adminService;
    private final ReportService reportService;
    private final ChatService chatService;
    private final ChatReportRepository chatReportRepository;
    private final InquiryService inquiryService;
    private final AdminRepository adminRepository;
    private final UserRepository userRepository;
    private final ReportRepository reportRepository; // ★ 신고 상태 변경용

    // 0) 관리자 REST 로그인
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {
        String adminId = body.get("admin_id");
        String adminPw = body.get("admin_pw");

        Optional<AdminEntity> adminOpt = adminRepository.findByAdminId(adminId);
        if (adminOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "존재하지 않는 관리자입니다."));
        }
        AdminEntity admin = adminOpt.get();

        // 평문 비교 (실서비스는 BCrypt 등 암호화 필수)
        if (!admin.getPassword().equals(adminPw)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "비밀번호가 올바르지 않습니다."));
        }
        // TODO: JWT 토큰 발급(여기선 예시로 dummy-token)
        String token = "dummy-token-for-" + adminId;

        return ResponseEntity.ok(Map.of(
                "token", token,
                "admin_id", admin.getAdminId(),
                "nickname", admin.getNickname(),
                "role", admin.getRole(),
                "status", admin.getStatus()
        ));
    }

    // 1) 회원 관리 조회
    @GetMapping("/members")
    public ResponseEntity<List<UserEntity>> getAllMembers() {
        return ResponseEntity.ok(adminService.getAllUsers());
    }

    // 1-1) 회원 상태 변경
    @PatchMapping("/members/{userId}/status")
    public ResponseEntity<?> updateMemberStatus(
            @PathVariable Long userId,
            @RequestBody Map<String, String> body
    ) {
        String newStatus = body.get("status");
        if (newStatus == null || newStatus.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "status 필드가 필요합니다."));
        }
        Optional<UserEntity> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "해당 사용자를 찾을 수 없습니다."));
        }
        UserEntity user = userOpt.get();
        user.setStatus(newStatus);
        userRepository.save(user);
        return ResponseEntity.ok().build();
    }

    // 2) 일반 신고 관리 조회
    @GetMapping("/reports")
    public ResponseEntity<List<ReportEntity>> getAllReports() {
        return ResponseEntity.ok(reportService.findAll());
    }

    // 2-1) 일반 신고 상태 변경 (String → Enum 변환)
    @PatchMapping("/reports/{id}")
    public ResponseEntity<?> updateReportStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body
    ) {
        String newStatus = body.get("status");
        if (newStatus == null || newStatus.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "status 필드가 필요합니다."));
        }
        Optional<ReportEntity> reportOpt = reportRepository.findById(id);
        if (reportOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "해당 신고를 찾을 수 없습니다."));
        }
        ReportEntity report = reportOpt.get();
        try {
            ReportEntity.Status statusEnum = ReportEntity.Status.valueOf(newStatus);
            report.setStatus(statusEnum);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", "잘못된 status 값입니다."));
        }
        reportRepository.save(report);
        return ResponseEntity.ok().build();
    }

    // 3) 채팅 로그 전체 조회
    @GetMapping("/chatlogs")
    public ResponseEntity<List<ChatMessageDTO>> getAllChatLogs() {
        List<ChatMessageDTO> logs = chatService.getAllChatMessages();
        return ResponseEntity.ok(logs);
    }

    // 4) 채팅 신고 목록 조회
    @GetMapping("/chat-reports")
    public ResponseEntity<List<ChatReportDto>> getAllChatReports() {
        List<ChatReport> reports = chatReportRepository.findAll();
        List<ChatReportDto> dtos = reports.stream()
            .map(ChatReportDto::fromEntity)
            .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    // 5) 채팅 신고 처리
    @PatchMapping("/chat-reports/{id}/process")
    public ResponseEntity<Void> processChatReport(
        @PathVariable Long id,
        @RequestBody Map<String, String> body
    ) {
        ChatReport report = chatReportRepository.findById(id)
            .orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_FOUND, "신고가 없습니다: " + id));

        String raw = body.get("status");
        try {
            ChatReport.ReportStatus status = ChatReport.ReportStatus.valueOf(raw);
            report.setStatus(status);
            chatReportRepository.save(report);
            return ResponseEntity.ok().build();
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST, "잘못된 status: " + raw);
        }
    }

    // 6) 1:1 문의 전체 조회
    @GetMapping("/inquiries")
    public ResponseEntity<List<InquiryEntity>> getAllInquiries() {
        return ResponseEntity.ok(inquiryService.getAllInquiries());
    }

    // 7) 1:1 문의 답변 저장
    @PostMapping("/inquiries/{id}/reply")
    public ResponseEntity<Void> replyToInquiry(
        @PathVariable Long id,
        @RequestBody Map<String, String> body
    ) {
        String reply = body.get("reply");
        if (reply == null || reply.trim().isEmpty()) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST, "reply 필드가 필요합니다.");
        }
        inquiryService.replyToInquiry(id, reply.trim());
        return ResponseEntity.ok().build();
    }

    // ---------------- 채팅 신고용 DTO ----------------
    @Data
    @AllArgsConstructor
    static class ChatReportDto {
        private Long id;
        private Long messageId;
        private String reporterNickname;
        private String reason;
        private String status;
        private LocalDateTime createdAt;

        static ChatReportDto fromEntity(ChatReport e) {
            return new ChatReportDto(
                e.getId(),
                e.getMessageId(),
                e.getReporter().getNickname(),
                e.getReason(),
                e.getStatus().name(),
                e.getCreatedAt()
            );
        }
    }
}
