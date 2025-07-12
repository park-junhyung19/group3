package com.group3.askmyfriend.config;

import com.group3.askmyfriend.service.AdminDetailsService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import jakarta.servlet.http.HttpServletResponse;

// ★ DummyJwtAuthenticationFilter import 추가
import com.group3.askmyfriend.config.DummyJwtAuthenticationFilter;

@Configuration
@RequiredArgsConstructor
public class AdminSecurityConfig {

    private final AdminDetailsService adminDetailsService;
    private final DummyJwtAuthenticationFilter dummyJwtAuthenticationFilter; // ★ 필터 주입

    // ✅ 암호화 없이 평문 그대로 비교하는 PasswordEncoder (개발 테스트용)
    @Bean
    public PasswordEncoder adminPasswordEncoder() {
        return new PasswordEncoder() {
            @Override
            public String encode(CharSequence rawPassword) {
                return rawPassword.toString();
            }

            @Override
            public boolean matches(CharSequence rawPassword, String encodedPassword) {
                return rawPassword.toString().equals(encodedPassword);
            }
        };
    }

    @Bean
    public DaoAuthenticationProvider adminAuthenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(adminDetailsService);
        provider.setPasswordEncoder(adminPasswordEncoder());
        return provider;
    }

    @Bean
    public SecurityFilterChain adminSecurityFilterChain(HttpSecurity http) throws Exception {
        // ✅ REST API(/api/admin/**)와 HTML 폼(/admin/**) 모두 보안 필터 적용
        http.securityMatcher("/admin/**", "/admin-login", "/admin-login/**", "/api/admin/**");

        http.csrf(AbstractHttpConfigurer::disable);

        http.authenticationProvider(adminAuthenticationProvider());

        http.authorizeHttpRequests(auth -> auth
                // ✅ REST 로그인 API는 모두 허용
                .requestMatchers("/api/admin/login").permitAll()
                // ✅ HTML 폼 로그인도 모두 허용
                .requestMatchers("/admin-login", "/admin-login/**").permitAll()
                // ✅ 관리자 페이지, REST 관리자 API는 SUPER_ADMIN만 허용
                .requestMatchers("/admin/**", "/api/admin/**").hasRole("SUPER_ADMIN")
                .anyRequest().denyAll()
        );

        // ✅ REST 인증 실패시 JSON 반환 (중요!)
        http.exceptionHandling()
            .authenticationEntryPoint((request, response, authException) -> {
                response.setContentType("application/json");
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.getWriter().write("{\"error\": \"인증 필요\"}");
            });

        // ✅ HTML 폼 로그인 설정 (REST API에는 영향 없음)
        http.formLogin(form -> form
                .loginPage("/admin-login")
                .loginProcessingUrl("/admin-login")
                .defaultSuccessUrl("/admin/dashboard", true)
                .usernameParameter("admin_id")
                .passwordParameter("admin_pw")
        );

        // ★★★ 여기에서 필터 등록!
        http.addFilterBefore(dummyJwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
