package com.group3.askmyfriend.repository;

import com.group3.askmyfriend.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.List;

@Repository
public interface UserRepository extends JpaRepository<UserEntity, Long> {
    
    // 이메일로 사용자 조회
    Optional<UserEntity> findByEmail(String email);
    
    // 닉네임으로 사용자 조회
    Optional<UserEntity> findByNickname(String nickname);
    
    // 로그인 ID로 사용자 조회
    Optional<UserEntity> findByLoginId(String loginId);
    
    // 내부 ID로 사용자 조회
    Optional<UserEntity> findByUserId(Long userId);
    
    // 닉네임으로 유사 검색 (대소문자 무시)
    List<UserEntity> findByNicknameContainingIgnoreCase(String nickname);
}
