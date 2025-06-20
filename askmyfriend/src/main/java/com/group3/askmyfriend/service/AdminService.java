package com.group3.askmyfriend.service;

import com.group3.askmyfriend.entity.AdminEntity;
import com.group3.askmyfriend.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final AdminRepository adminRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    public AdminEntity authenticate(String adminId, String password) {
        AdminEntity admin = adminRepository.findByAdminId(adminId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 관리자 ID입니다."));

        if (!admin.getPassword().equals(password)) {
            throw new IllegalArgumentException("비밀번호가 올바르지 않습니다.");
        }


        return admin;
    }
}
