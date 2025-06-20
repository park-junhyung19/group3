package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.entity.AdminEntity;
import com.group3.askmyfriend.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/admin-login")
    public String showLoginPage(@RequestParam(value = "error", required = false) String error, Model model) {
        if (error != null) {
            model.addAttribute("errorMessage", "로그인에 실패했습니다.");
        }
        return "admin_login"; // templates/admin_login.html
    }

    @PostMapping("/admin-login")
    public String handleLogin(@RequestParam("admin_id") String adminId,
                               @RequestParam("admin_pw") String password,
                               Model model) {
        try {
            AdminEntity admin = adminService.authenticate(adminId, password);
            // 세션 또는 인증 로직 추가 가능
            return "redirect:/admin/dashboard";
        } catch (IllegalArgumentException e) {
            model.addAttribute("errorMessage", e.getMessage());
            return "admin_login";
        }
    }
    @GetMapping("/admin/dashboard")
    public String showDashboard() {
        return "admin/dashboard";
    }

}
