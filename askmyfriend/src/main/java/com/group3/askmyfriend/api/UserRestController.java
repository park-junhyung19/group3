package com.group3.askmyfriend.api;

import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.User;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping(value = "/api/users", produces = MediaType.APPLICATION_JSON_VALUE + ";charset=UTF-8")
public class UserRestController {

    @Autowired
    private UserService userService;

    /** 
     * 현재 로그인한 사용자의 프로필 정보를 반환합니다.
     * 로그인되지 않았다면 401, 사용자가 없으면 404를 반환합니다.
     */
    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> getCurrentUser(
            @AuthenticationPrincipal User springUser
    ) {
        if (springUser == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        UserEntity me = userService.findByLoginId(springUser.getUsername())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        Map<String, Object> dto = new HashMap<>();
        dto.put("loginId", me.getLoginId());
        dto.put("nickname", me.getNickname());
        // UserEntity.getProfileImg() 은 "/uploads/파일명.jpg" 형태여야 합니다.
        dto.put("profileImg", me.getProfileImg());

        return ResponseEntity.ok(dto);
    }
}
