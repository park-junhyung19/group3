	package com.group3.askmyfriend.jwt;
	
	import io.jsonwebtoken.*;
	import io.jsonwebtoken.security.Keys;
	import org.springframework.beans.factory.annotation.Value;
	import org.springframework.security.core.Authentication;
	import org.springframework.stereotype.Component;
	
	import java.security.Key;
	import java.util.Date;
	
	@Component
	public class JwtTokenProvider {
	
	    @Value("${jwt.secret}")
	    private String secret;
	
	    @Value("${jwt.expiration-ms}")
	    private long expirationMs;
	
	    // 비밀 키 생성
	    private Key getSigningKey() {
	        return Keys.hmacShaKeyFor(secret.getBytes());
	    }
	
	    // 토큰 생성
	    public String generateToken(Authentication authentication) {
	        String username = authentication.getName(); // 유저 아이디 또는 이메일
	        Date now = new Date();
	        Date expiryDate = new Date(now.getTime() + expirationMs);
	
	        return Jwts.builder()
	                .setSubject(username)
	                .setIssuedAt(now)
	                .setExpiration(expiryDate)
	                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
	                .compact();
	    }
	
	    // 토큰에서 사용자명(ID) 추출
	    public String getUsernameFromToken(String token) {
	        return Jwts.parserBuilder()
	                .setSigningKey(getSigningKey())
	                .build()
	                .parseClaimsJws(token)
	                .getBody()
	                .getSubject();
	    }
	
	    // 토큰 유효성 검사
	    public boolean validateToken(String token) {
	        try {
	            Jwts.parserBuilder()
	                    .setSigningKey(getSigningKey())
	                    .build()
	                    .parseClaimsJws(token);
	            return true;
	        } catch (ExpiredJwtException e) {
	            System.out.println("JWT 만료됨: " + e.getMessage());
	        } catch (JwtException | IllegalArgumentException e) {
	            System.out.println("JWT 유효하지 않음: " + e.getMessage());
	        }
	        return false;
	    }
	}
