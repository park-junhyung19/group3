package com.group3.askmyfriend.service;

import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.group3.askmyfriend.dto.SignupDTO;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.UserRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    @PersistenceContext
    private EntityManager entityManager;

    @Autowired
    public UserService(UserRepository userRepository, BCryptPasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public void save(SignupDTO signupDTO) {
        if (!signupDTO.getPassword().equals(signupDTO.getPasswordConfirm())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        if (userRepository.findByLoginId(signupDTO.getLoginId()).isPresent()) {
            throw new RuntimeException("이미 존재하는 아이디입니다.");
        }

        if (userRepository.findByEmail(signupDTO.getEmail()).isPresent()) {
            throw new RuntimeException("이미 가입된 이메일입니다.");
        }

        UserEntity user = new UserEntity();
        user.setLoginId(signupDTO.getLoginId());
        user.setUserName(signupDTO.getUserName());
        user.setPassword(passwordEncoder.encode(signupDTO.getPassword()));
        user.setEmail(signupDTO.getEmail());
        user.setNickname(signupDTO.getNickname());
        user.setPhone(signupDTO.getPhone());
        user.setStatus("ACTIVE");

        userRepository.save(user);
    }

    public void updatePassword(String email, String newPassword) {
        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("해당 이메일의 사용자가 없습니다."));
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    public Optional<UserEntity> findByLoginId(String loginId) {
        return userRepository.findByLoginId(loginId);
    }
}
