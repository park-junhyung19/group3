package com.group3.askmyfriend.config;

import com.group3.askmyfriend.jwt.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@RequiredArgsConstructor
@Order(1)
public class ApiSecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public SecurityFilterChain apiSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            // JWT 전용 체인: 인증·회원가입, 관리자, 설정 API 포함
            .securityMatcher(
                "/api/auth/**",
                "/api/admin/**",
                "/api/setting/**",
                "/api/posts/**", // ✅ 포함됨
                "/likes/**" // ✅ 추가됨

            )
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(sess ->
                sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .authorizeHttpRequests(auth -> auth
                // 회원가입·로그인 API는 모두 허용
                .requestMatchers("/api/auth/signup", "/api/auth/login").permitAll()
                // ✅ 이미지 조회는 인증 없이 허용
                .requestMatchers("/api/posts/image").permitAll()
                .requestMatchers("/api/posts/shorts").permitAll()
                .requestMatchers("/uploads/**").permitAll() // ✅ 추가
                .requestMatchers("/likes/**").authenticated() // ✅ 또는 permitAll() 테스트용으로 가능



                // 관리자 API는 ADMIN 역할 필요
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                // 비밀번호 확인/변경 API는 인증된 사용자만
                .requestMatchers("/api/setting/**").authenticated()
                
                .requestMatchers("/api/posts/**").permitAll()

                // 그 외 API도 인증 필요
                .anyRequest().authenticated()
            )
            // JWT 토큰 검증 필터를 UsernamePasswordAuthenticationFilter 앞에 등록
            .addFilterBefore(
                jwtAuthenticationFilter,
                UsernamePasswordAuthenticationFilter.class
            )
            // 폼 로그인, HTTP Basic, 로그아웃 기능 비활성화
            .formLogin(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            .logout(AbstractHttpConfigurer::disable);

        return http.build();
    }
} 