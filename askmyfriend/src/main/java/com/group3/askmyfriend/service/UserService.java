package com.group3.askmyfriend.service;

import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional; // ✅ 추가 필요

import com.group3.askmyfriend.dto.SignupDTO;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.UserRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class UserService {

	private final UserRepository userRepository;
	private final BCryptPasswordEncoder bCryptPasswordEncoder;

	@PersistenceContext
	private EntityManager entityManager;

	@Autowired
	public UserService(UserRepository userRepository, BCryptPasswordEncoder bCryptPasswordEncoder) {
		this.userRepository = userRepository;
		this.bCryptPasswordEncoder = bCryptPasswordEncoder;
	}

	// 회원 가입 저장
	@Transactional // ✅ 이거 꼭 필요!
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
		user.setUserName(signupDTO.getUserName()); // null 방지 주의
		user.setPassword(bCryptPasswordEncoder.encode(signupDTO.getPassword()));
		user.setEmail(signupDTO.getEmail());
		user.setNickname(signupDTO.getNickname());
		user.setPhone(signupDTO.getPhone());
		user.setStatus("ACTIVE");

		userRepository.save(user);
	}

	public Optional<UserEntity> findByLoginId(String loginId) {
		return userRepository.findByLoginId(loginId);
	}
}
