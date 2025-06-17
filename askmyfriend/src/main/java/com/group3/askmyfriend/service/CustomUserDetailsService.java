package com.group3.askmyfriend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.UserRepository;

import java.util.Collections;

@Service
public class CustomUserDetailsService implements UserDetailsService {

	private final UserRepository userRepository;

	@Autowired
	public CustomUserDetailsService(UserRepository userRepository) {
		this.userRepository = userRepository;
	}

	@Override
	public UserDetails loadUserByUsername(String loginId) throws UsernameNotFoundException {
		UserEntity user = userRepository.findByLoginId(loginId)
				.orElseThrow(() -> new UsernameNotFoundException("해당 아이디를 찾을 수 없습니다: " + loginId));

		return new CustomUser(user);
	}

	public static class CustomUser extends org.springframework.security.core.userdetails.User {
		private final String nickname;

		public CustomUser(UserEntity user) {
			super(user.getLoginId(), user.getPassword(),
					Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER")));
			this.nickname = user.getNickname();
		}

		public String getNickname() {
			return nickname;
		}
	}
}
