package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.dto.LoginDTO;
import com.group3.askmyfriend.dto.SignupDTO;
import com.group3.askmyfriend.service.UserService;

import jakarta.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/auth")
public class AuthController {

    private final UserService userService;

    @Autowired
    public AuthController(UserService userService) {
        this.userService = userService;
    }

    // 회원 가입 폼
    @GetMapping("/signup")
    public String signupForm() {
        return "signup"; // templates/signup.html
    }

    // 회원 가입 처리
    @PostMapping("/signup")
    public String signup(@Valid SignupDTO signupDTO, BindingResult result, Model model) {
        if (result.hasErrors()) {
            return "signup";
        }

        try {
            signupDTO.validatePassword(); // 비밀번호 복잡성 검사
            userService.save(signupDTO);  // 내부에서 BCrypt 적용되어야 함
            return "redirect:/auth/login";
        } catch (Exception e) {
            model.addAttribute("error", e.getMessage());
            return "signup";
        }
    }

    @GetMapping("/login")
    public String loginForm() {
        return "login"; // templates/login.html
    }

}
