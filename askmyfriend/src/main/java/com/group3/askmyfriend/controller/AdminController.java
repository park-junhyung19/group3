package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.dto.ChatLogDto;
import com.group3.askmyfriend.entity.AdminEntity;
import com.group3.askmyfriend.entity.InquiryEntity;
import com.group3.askmyfriend.entity.ReportEntity;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.entity.ChatReport;
import com.group3.askmyfriend.service.AdminService;
import com.group3.askmyfriend.service.ChatLogService;
import com.group3.askmyfriend.service.InquiryService;
import com.group3.askmyfriend.service.ReportService;
import com.group3.askmyfriend.service.UserService;
import com.group3.askmyfriend.service.ChatReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Controller
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final ChatLogService chatLogService;
    private final InquiryService inquiryService;
    private final UserService userService;
    private final ReportService reportService;
    private final ChatReportService chatReportService;

    // 관리자 로그인 페이지
    @GetMapping("/admin-login")
    public String showLoginPage(@RequestParam(value = "error", required = false) String error, Model model) {
        if (error != null) {
            model.addAttribute("errorMessage", "로그인에 실패했습니다.");
        }
        return "admin_login";
    }

    // 로그인 처리
    @PostMapping("/admin-login")
    public String handleLogin(@RequestParam("admin_id") String adminId,
                              @RequestParam("admin_pw") String password,
                              Model model) {
        try {
            AdminEntity admin = adminService.authenticate(adminId, password);
            return "redirect:/admin/dashboard";
        } catch (IllegalArgumentException e) {
            model.addAttribute("errorMessage", e.getMessage());
            return "admin_login";
        }
    }

    // 관리자 대시보드
    @GetMapping("/admin/dashboard")
    public String showDashboard() {
        return "admin/dashboard";
    }

    // 회원 목록 보기
    @GetMapping("/admin/members")
    public String showMemberList(Model model) {
        List<UserEntity> users = adminService.getAllUsers();
        model.addAttribute("userList", users);
        return "admin/members";
    }

    // 채팅 로그 보기
    @GetMapping("/admin/chatlog")
    public String showChatLog(Model model) {
        List<ChatLogDto> chatList = chatLogService.getAllLogs();
        model.addAttribute("chatList", chatList);
        return "admin/chatlog";
    }

    // 1:1 문의 목록 보기
    @GetMapping("/admin/inquiries")
    public String showInquiries(Model model) {
        List<InquiryEntity> inquiries = inquiryService.getAllInquiries();
        model.addAttribute("inquiries", inquiries);
        return "admin/inquiries";
    }

    // 1:1 문의 답변 처리
    @PostMapping("/admin/inquiries/{id}/reply")
    public String replyToInquiry(@PathVariable Long id, @RequestParam String reply) {
        inquiryService.replyToInquiry(id, reply);
        return "redirect:/admin/inquiries";
    }

    // 회원 상태 변경 처리
    @PostMapping("/admin/members/status")
    public String updateUserStatus(@RequestParam Long userId,
                                   @RequestParam String status) {
        userService.updateStatus(userId, status);
        return "redirect:/admin/members";
    }

    // 신고 목록 보기 (기존 게시글/댓글 신고)
    @GetMapping("/admin/reports")
    public String showReportList(Model model) {
        List<ReportEntity> reports = reportService.findAll();
        model.addAttribute("reports", reports);
        return "admin/reports";
    }

    // 채팅 신고 목록 보기
    @GetMapping("/admin/chat-reports")
    public String showChatReportList(Model model) {
        List<ChatReport> chatReports = chatReportService.getAllChatReports();
        model.addAttribute("reports", chatReports);
        return "admin/chatreports";
    }

    // 채팅 신고 처리 API (수정됨)
    @PatchMapping("/admin/chat-reports/{id}/process")
    @ResponseBody
    public ResponseEntity<String> processChatReport(@PathVariable Long id, 
                                                  @RequestBody Map<String, String> request) {
        try {
            String status = request.get("status");
            // 실제 채팅 신고 처리 로직 활성화
            chatReportService.updateStatus(id, status);
            
            return ResponseEntity.ok("success");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("error");
        }
    }
}
