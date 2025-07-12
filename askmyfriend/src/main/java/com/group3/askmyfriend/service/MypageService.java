package com.group3.askmyfriend.service;

import com.group3.askmyfriend.dto.MypageDto;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.entity.PostEntity;
import com.group3.askmyfriend.repository.UserRepository;
import com.group3.askmyfriend.repository.FollowRepository;
import com.group3.askmyfriend.repository.PostRepository;
import com.group3.askmyfriend.repository.CommentRepository;
import com.group3.askmyfriend.repository.LikeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class MypageService {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private FollowRepository followRepository;
    @Autowired
    private PostRepository postRepository;
    @Autowired
    private CommentRepository commentRepository;
    @Autowired
    private LikeRepository likeRepository;

    /** 마이페이지 기본 정보 조회 */
    public MypageDto getMypageInfo(String loginId) {
        UserEntity user = userRepository.findByLoginId(loginId)
            .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다: " + loginId));

        String profileImg = user.getProfileImg();
        if (profileImg == null || profileImg.isEmpty()) {
            profileImg = "/img/profile_default.jpg";
        }
        String backgroundImg = user.getBackgroundImg();
        if (backgroundImg == null || backgroundImg.isEmpty()) {
            backgroundImg = "/img/cover_default.jpg";
        }

        int followingCount = 0;
        int followerCount = 0;
        try {
            followingCount = (int) followRepository.countByFollower(user);
            followerCount  = (int) followRepository.countByFollowing(user);
        } catch (Exception e) {
            System.err.println("팔로우 수 계산 중 오류: " + e.getMessage());
        }

        return new MypageDto(
            user.getLoginId(),
            user.getNickname(),
            user.getLoginId(),
            user.getBio(),
            profileImg,
            backgroundImg,
            followingCount,
            followerCount,
            user.getCreatedDate(),
            user.getPrivacy()
        );
    }

    /** 본인이 작성한 게시물 목록 (최신순) */
    public List<PostEntity> getMyPosts(String loginId) {
        try {
            UserEntity user = userRepository.findByLoginId(loginId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다: " + loginId));
            return postRepository.findByAuthorOrderByCreatedAtDesc(user);
        } catch (Exception e) {
            System.err.println("게시물 조회 중 오류: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /** 본인이 댓글 단 게시물 목록 (중복 제거 + 최신순) */
    public List<PostEntity> getMyRepliedPosts(String loginId) {
        try {
            return commentRepository
                .findDistinctPostsByAuthorLoginIdOrderByPostCreatedAtDesc(loginId);
        } catch (Exception e) {
            System.err.println("댓글 단 게시물 조회 중 오류: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /** 본인이 좋아요 누른 게시물 목록 (게시물 생성일 기준 최신순) */
    public List<PostEntity> getMyLikedPosts(String loginId) {
        try {
            UserEntity user = userRepository.findByLoginId(loginId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다: " + loginId));
            String userEmail = user.getEmail();
            return likeRepository.findPostsByUserEmailOrderByPostCreatedAtDesc(userEmail);
        } catch (Exception e) {
            System.err.println("좋아요 게시물 조회 중 오류: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /** 본인이 업로드한 미디어 포함 게시물 목록 (최신순) */
    public List<PostEntity> getMyMediaList(String loginId) {
        try {
            UserEntity user = userRepository.findByLoginId(loginId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다: " + loginId));
            List<PostEntity> allPosts = postRepository.findByAuthorOrderByCreatedAtDesc(user);
            List<PostEntity> media = new ArrayList<>();
            for (PostEntity post : allPosts) {
                if (post.getImagePath() != null && !post.getImagePath().isEmpty()) {
                    media.add(post);
                }
            }
            return media;
        } catch (Exception e) {
            System.err.println("미디어 조회 중 오류: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /** 팔로우 수를 UserEntity에 업데이트 */
    public void updateFollowCounts(String loginId) {
        try {
            UserEntity user = userRepository.findByLoginId(loginId)
                .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다: " + loginId));
            int followingCount = (int) followRepository.countByFollower(user);
            int followerCount  = (int) followRepository.countByFollowing(user);
            user.setFollowingCount(followingCount);
            user.setFollowerCount(followerCount);
            userRepository.save(user);
        } catch (Exception e) {
            System.err.println("팔로우 수 업데이트 중 오류: " + e.getMessage());
        }
    }

    /** 프로필 정보 업데이트 */
    public void updateProfile(String loginId,
                              MultipartFile backgroundImg,
                              MultipartFile profileImg,
                              String nickname,
                              String bio,
                              String privacy) {
        UserEntity user = userRepository.findByLoginId(loginId)
            .orElseThrow(() -> new RuntimeException("유저를 찾을 수 없습니다: " + loginId));

        String uploadDir = System.getProperty("user.dir") + "/uploads/";
        File uploadPath = new File(uploadDir);
        if (!uploadPath.exists()) {
            uploadPath.mkdirs();
        }

        // 배경 이미지 처리
        if (backgroundImg != null && !backgroundImg.isEmpty()) {
            String ext = extractExtension(backgroundImg.getOriginalFilename());
            String bgFileName = UUID.randomUUID().toString() + ext;
            File bgFile = new File(uploadDir + bgFileName);
            try {
                backgroundImg.transferTo(bgFile);
                user.setBackgroundImg("/uploads/" + bgFileName);
            } catch (IOException e) {
                throw new RuntimeException("배경 이미지 업로드 실패", e);
            }
        }

        // 프로필 이미지 처리
        if (profileImg != null && !profileImg.isEmpty()) {
            String ext = extractExtension(profileImg.getOriginalFilename());
            String pfFileName = UUID.randomUUID().toString() + ext;
            File pfFile = new File(uploadDir + pfFileName);
            try {
                profileImg.transferTo(pfFile);
                user.setProfileImg("/uploads/" + pfFileName);
            } catch (IOException e) {
                throw new RuntimeException("프로필 이미지 업로드 실패", e);
            }
        }

        // 기본 이미지 설정
        if (user.getProfileImg() == null || user.getProfileImg().isEmpty()) {
            user.setProfileImg("/img/profile_default.jpg");
        }
        if (user.getBackgroundImg() == null || user.getBackgroundImg().isEmpty()) {
            user.setBackgroundImg("/img/cover_default.jpg");
        }

        // 기타 프로필 정보 업데이트
        user.setNickname(nickname);
        user.setBio(bio);
        if (privacy != null) {
            user.setPrivacy(privacy);
        }
        user.setModifiedDate(LocalDateTime.now());
        userRepository.save(user);
    }

    /** 파일명에서 확장자 추출 */
    private String extractExtension(String filename) {
        if (filename == null) return "";
        int dotIdx = filename.lastIndexOf('.');
        return (dotIdx != -1) ? filename.substring(dotIdx) : "";
    }
}
