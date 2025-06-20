package com.group3.askmyfriend.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;

import com.group3.askmyfriend.service.CustomUserDetailsService;

// 스프링 시큐리티 설정 클래스
@Configuration
public class SecurityConfig {

    // userDetailsService 사용 추가
    private final CustomUserDetailsService userDetailsService;
    // 로그인 실패 핸들러 의존성 주입
    private final AuthenticationFailureHandler customAuthFailureHandler;

    @Autowired
    public SecurityConfig(CustomUserDetailsService userDetailsService,
                          AuthenticationFailureHandler customAuthFailureHandler) {
        this.userDetailsService = userDetailsService;
        this.customAuthFailureHandler = customAuthFailureHandler;
    }

    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // 스프링 시큐리티의 보안 필터 체인
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                .sessionFixation()
                .migrateSession()
                .maximumSessions(1)
                .expiredUrl("/auth/login?expired")
        ).authorizeHttpRequests(auth -> auth
                .requestMatchers(
                        new AntPathRequestMatcher("/"),
                        new AntPathRequestMatcher("/auth/login"),
                        new AntPathRequestMatcher("/auth/signup"),
                        new AntPathRequestMatcher("/css/**"),
                        new AntPathRequestMatcher("/js/**"),
                        new AntPathRequestMatcher("/images/**"),
                        new AntPathRequestMatcher("/error/**"),
                        new AntPathRequestMatcher("/ws-chat/**")  // WebSocket 경로 추가
                ).permitAll()
                .anyRequest().authenticated()
        ).formLogin(form -> form
                .loginPage("/auth/login")
                .defaultSuccessUrl("/index", true)
                .failureHandler(customAuthFailureHandler)
                .failureUrl("/auth/login?error=true")
                .usernameParameter("loginId")
                .passwordParameter("password")
                .loginProcessingUrl("/auth/loginProc")

        ).logout(logout -> logout
                .logoutSuccessUrl("/auth/login")
                .invalidateHttpSession(true)
        ).csrf(AbstractHttpConfigurer::disable);

        return http.build();
    }
}