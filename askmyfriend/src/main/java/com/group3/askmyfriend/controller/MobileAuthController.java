package com.group3.askmyfriend.controller;

import com.group3.askmyfriend.dto.LoginDTO;
import com.group3.askmyfriend.dto.SignupDTO;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.jwt.JwtTokenProvider;
import com.group3.askmyfriend.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/auth") // 모바일/앱 전용 엔드포인트
public class MobileAuthController {

    private final UserService userService;
    private final JwtTokenProvider jwtTokenProvider;

    @Autowired
    public MobileAuthController(UserService userService, JwtTokenProvider jwtTokenProvider) {
        this.userService = userService;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    // 회원가입
    @PostMapping("/signup")
    public ResponseEntity<?> signup(@RequestBody SignupDTO signupDTO) {
        try {
            userService.save(signupDTO);
            return ResponseEntity.ok("회원가입 성공");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("회원가입 실패: " + e.getMessage());
        }
    }

    // 로그인 + JWT 발급
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginDTO loginDTO) {
        try {
            // ID/PW 확인
            UserEntity user = userService.validateLogin(loginDTO.getLoginId(), loginDTO.getPassword());

            // 권한 고정: ROLE_USER
            Authentication authentication = new UsernamePasswordAuthenticationToken(
                    user.getLoginId(),
                    null,
                    List.of(new SimpleGrantedAuthority("ROLE_USER"))
            );

            // JWT 토큰 생성
            String token = jwtTokenProvider.generateToken(authentication);

            // 토큰만 반환 (원한다면 사용자 정보도 함께 넣을 수 있음)
            return ResponseEntity.ok(Map.of("token", token));

        } catch (Exception e) {
            return ResponseEntity.status(401).body("로그인 실패: " + e.getMessage());
        }
    }
}
