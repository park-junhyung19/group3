package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.dto.LoginDTO;
import com.group3.askmyfriend.dto.SignupDTO;
import com.group3.askmyfriend.service.AuthService;
import com.group3.askmyfriend.service.UserService;

import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/auth")
public class AuthController {

    private final UserService userService;
    private final AuthService authService;

    @Autowired
    public AuthController(UserService userService, AuthService authService) {
        this.userService = userService;
        this.authService = authService;
    }

    // 회원가입 화면
    @GetMapping("/signup")
    public String signupForm() {
        return "signup";
    }

    // 회원가입 처리
    @PostMapping("/signup")
    public String signup(@Valid SignupDTO signupDTO, BindingResult result, Model model) {
        if (result.hasErrors()) {
            return "signup";
        }

        try {
            signupDTO.validatePassword();
            userService.save(signupDTO);
            return "redirect:/auth/login";
        } catch (Exception e) {
            model.addAttribute("error", e.getMessage());
            return "signup";
        }
    }

    // 로그인 화면
    @GetMapping("/login")
    public String loginForm() {
        return "login";
    }

    // 이메일 인증 화면
    @GetMapping("/email-verify")
    public String showEmailVerifyPage() {
        return "email-verify"; // templates/email-verify.html
    }

    // 인증번호 전송
    @PostMapping("/send-code")
    @ResponseBody
    public ResponseEntity<String> sendCode(@RequestParam String email) {
        authService.sendVerificationCode(email);
        return ResponseEntity.ok("인증번호가 전송되었습니다.");
    }

    // 인증번호 확인 및 세션 저장
    @PostMapping("/verify-code")
    @ResponseBody
    public ResponseEntity<Boolean> verifyCode(@RequestParam String email,
                                              @RequestParam String code,
                                              HttpSession session) {
        boolean isValid = authService.verifyCode(email, code);
        if (isValid) {
            session.setAttribute("verifiedEmail", email); // 세션에 저장
        }
        return ResponseEntity.ok(isValid);
    }

    // 비밀번호 재설정 화면
    @GetMapping("/reset-password")
    public String showResetPasswordPage(@RequestParam String email,
                                        HttpSession session,
                                        Model model) {
        String verifiedEmail = (String) session.getAttribute("verifiedEmail");
        if (verifiedEmail == null || !verifiedEmail.equals(email)) {
            return "redirect:/auth/login"; // 인증되지 않은 접근 차단
        }

        model.addAttribute("email", email);
        return "reset_password"; // templates/reset_password.html
    }

    // 비밀번호 재설정 처리
    @PostMapping("/reset-password")
    public String resetPassword(@RequestParam String email,
                                @RequestParam String newPassword,
                                HttpSession session,
                                Model model) {
        try {
            userService.updatePassword(email, newPassword);
            session.removeAttribute("verifiedEmail"); // 인증정보 초기화
            return "redirect:/auth/login?resetSuccess";
        } catch (Exception e) {
            model.addAttribute("error", "비밀번호 변경 실패: " + e.getMessage());
            return "reset_password";
        }
    }
    @GetMapping("/find-password")
    public String redirectToEmailVerifyPage() {
        return "email-verify"; // 파일명과 정확히 일치해야 함
    }

}
