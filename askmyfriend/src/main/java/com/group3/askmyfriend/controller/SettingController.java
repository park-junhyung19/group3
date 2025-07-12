package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.service.UserService;
import com.group3.askmyfriend.service.CustomUserDetailsService.CustomUser;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@Controller
@RequestMapping("/setting")
@RequiredArgsConstructor
public class SettingController {

    private final UserService userService;

    // ── 설정 화면 ──
    @GetMapping
    public String showSettingPage() {
        return "setting/setting";
    }

    // ── 이메일 변경 ──
    @GetMapping("/change-email")
    public String showChangeEmailPage(
            @AuthenticationPrincipal CustomUser userDetails,
            Model model
    ) {
        String currentEmail = userService
            .findByLoginId(userDetails.getUsername())
            .map(u -> u.getEmail())
            .orElse("");
        model.addAttribute("currentEmail", currentEmail);
        return "setting/change-email";
    }

    @GetMapping("/change-email-form")
    public String showChangeEmailFormPage() {
        return "setting/change-email-form";
    }

    @PostMapping("/change-emailProc")
    public String processChangeEmail(
            @RequestParam("newEmail") String newEmail,
            @AuthenticationPrincipal CustomUser userDetails
    ) {
        userService.findByLoginId(userDetails.getUsername())
                   .ifPresent(u -> userService.updateEmail(u.getUserId(), newEmail));
        return "redirect:/setting";
    }

    // ── 비밀번호 확인 (JSON API) ──
    @PostMapping(
      path = "/verify-password",
      consumes = MediaType.APPLICATION_JSON_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE
    )
    @ResponseBody
    public ResponseEntity<Map<String, String>> verifyPassword(
            @RequestBody Map<String, String> req,
            @AuthenticationPrincipal CustomUser userDetails
    ) {
        String current = req.get("currentPassword");
        Optional.ofNullable(userDetails)
                .map(CustomUser::getUsername)
                .flatMap(userService::findByLoginId)
                .ifPresentOrElse(
                    u -> {},
                    () -> { throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."); }
                );

        boolean matches = userService.checkPassword(userDetails.getUsername(), current);
        if (matches) {
            return ResponseEntity.ok(Map.of("message", "비밀번호 확인 성공"));
        } else {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "비밀번호가 일치하지 않습니다."));
        }
    }

    // ── 비밀번호 변경 (화면) ──
    @GetMapping("/change-password")
    public String showChangePasswordPage() {
        return "setting/change-password";
    }

    // ── 비밀번호 변경 (HTML form) ──
    @PostMapping(
      path = "/change-passwordProc",
      consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE
    )
    public String processChangePasswordForm(
            @RequestParam String currentPassword,
            @RequestParam String newPassword,
            @RequestParam String confirmPassword,
            @AuthenticationPrincipal CustomUser userDetails,
            Model model
    ) {
        try {
            Long userId = userService.findByLoginId(userDetails.getUsername())
                                     .orElseThrow(() -> new IllegalArgumentException("사용자 정보가 없습니다."))
                                     .getUserId();
            userService.changePassword(userId, currentPassword, newPassword, confirmPassword);
            return "redirect:/setting";
        } catch (IllegalArgumentException e) {
            model.addAttribute("error", e.getMessage());
            return "setting/change-password";
        }
    }

    // ── 비밀번호 변경 (JSON API) ──
    @PostMapping(
      path = "/change-passwordProc",
      consumes = MediaType.APPLICATION_JSON_VALUE,
      produces = MediaType.APPLICATION_JSON_VALUE
    )
    @ResponseBody
    public ResponseEntity<Map<String, String>> processChangePasswordApi(
            @RequestBody Map<String, String> req,
            @AuthenticationPrincipal CustomUser userDetails
    ) {
        try {
            Long userId = userService.findByLoginId(userDetails.getUsername())
                                     .orElseThrow(() -> new IllegalArgumentException("사용자 정보가 없습니다."))
                                     .getUserId();

            String current = req.get("currentPassword");
            String neu     = req.get("newPassword");
            String confirm = req.get("confirmPassword");

            userService.changePassword(userId, current, neu, confirm);
            return ResponseEntity.ok(Map.of("message", "비밀번호가 변경되었습니다."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("error", e.getMessage()));
        }
    }

    // ── 전화번호 변경 ──
    @GetMapping("/change-phone")
    public String showChangePhonePage(
            @AuthenticationPrincipal CustomUser userDetails,
            Model model
    ) {
        userService.findByLoginId(userDetails.getUsername())
                   .ifPresent(u -> model.addAttribute("currentPhone", u.getPhone()));
        return "setting/change-phone";
    }

    @PostMapping("/change-phoneProc")
    public String processChangePhone(
            @RequestParam("newPhone") String newPhone,
            @AuthenticationPrincipal CustomUser userDetails,
            Model model
    ) {
        try {
            Long userId = userService.findByLoginId(userDetails.getUsername())
                                     .orElseThrow(() -> new IllegalArgumentException("사용자 정보가 없습니다."))
                                     .getUserId();
            userService.updatePhone(userId, newPhone);
            return "redirect:/setting";
        } catch (IllegalArgumentException e) {
            model.addAttribute("error", e.getMessage());
            return "setting/change-phone";
        }
    }
}
