package com.group3.askmyfriend.config;

import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

import java.security.Principal;

@ControllerAdvice
public class GlobalControllerAdvice {
    
    @Autowired
    private UserService userService;
    
    /** 모든 Controller에서 사용할 수 있는 전역 사용자 정보 */
    @ModelAttribute("user")
    public UserEntity getCurrentUser(Principal principal) {
        if (principal != null) {
            try {
                return userService.findByLoginId(principal.getName())
                                  .orElse(null);
            } catch (Exception e) {
                System.err.println("사용자 정보 조회 실패: " + e.getMessage());
                return null;
            }
        }
        return null;
    }
    
    /** 로그인 상태 확인 */
    @ModelAttribute("isLoggedIn")
    public boolean isLoggedIn(Principal principal) {
        return principal != null;
    }
    
    /** 현재 사용자 이메일 */
    @ModelAttribute("currentUserEmail")
    public String getCurrentUserEmail(Principal principal) {
        return principal != null ? principal.getName() : null;
    }

    /** 현재 요청된 URI */
    @ModelAttribute("currentPath")
    public String currentPath(HttpServletRequest request) {
        return request.getRequestURI();
    }
}
