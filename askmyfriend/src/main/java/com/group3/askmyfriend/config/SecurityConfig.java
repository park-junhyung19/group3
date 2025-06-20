package com.group3.askmyfriend.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;

import com.group3.askmyfriend.service.CustomUserDetailsService;

@Configuration
@Order(2) // ★ 사용자용 보안 설정은 두 번째로 적용
public class SecurityConfig {

    private final CustomUserDetailsService userDetailsService;
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

    @Bean
    public DaoAuthenticationProvider userAuthenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public SecurityFilterChain userSecurityFilterChain(HttpSecurity http) throws Exception {
        http.securityMatcher("/**"); // ✅ 사용자 요청은 전부 여기로

        http.sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                .sessionFixation().migrateSession()
                .maximumSessions(1).expiredUrl("/auth/login?expired")
        );

        http.csrf(AbstractHttpConfigurer::disable);

        http.authenticationProvider(userAuthenticationProvider());

        http.authorizeHttpRequests(auth -> auth
                .requestMatchers(
                        new AntPathRequestMatcher("/"),
                        new AntPathRequestMatcher("/auth/login"),
                        new AntPathRequestMatcher("/auth/signup"),
                        new AntPathRequestMatcher("/css/**"),
                        new AntPathRequestMatcher("/js/**"),
                        new AntPathRequestMatcher("/images/**"),
                        new AntPathRequestMatcher("/error/**")
                ).permitAll()
                .anyRequest().authenticated()
        );

        http.formLogin(form -> form
                .loginPage("/auth/login")
                .loginProcessingUrl("/auth/loginProc")
                .defaultSuccessUrl("/index", true)
                .failureHandler(customAuthFailureHandler)
                .failureUrl("/auth/login?error=true")
                .usernameParameter("loginId")
                .passwordParameter("password")
        );

        http.logout(logout -> logout
                .logoutSuccessUrl("/auth/login")
                .invalidateHttpSession(true)
        );

        return http.build();
    }
}
