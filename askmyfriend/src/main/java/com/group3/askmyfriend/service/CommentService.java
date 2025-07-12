package com.group3.askmyfriend.service;

import com.group3.askmyfriend.entity.CommentEntity;
import com.group3.askmyfriend.entity.PostEntity;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.entity.NotificationType;
import com.group3.askmyfriend.repository.CommentRepository;
import com.group3.askmyfriend.repository.PostRepository;
import com.group3.askmyfriend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class CommentService {

    @Autowired
    private CommentRepository commentRepository;

    @Autowired
    private PostRepository postRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NotificationService notificationService;

    /**
     * 게시글에 댓글 추가 및 알림 생성
     *
     * @param postId       댓글을 달 게시물 ID
     * @param content      댓글 내용
     * @param authorEmail  댓글 작성자 이메일
     * @return 저장된 CommentEntity
     */
    @Transactional
    public CommentEntity addComment(Long postId, String content, String authorEmail) {
        // 1) 게시글 조회
        PostEntity post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다: " + postId));
        
        // 2) 댓글 작성자 조회
        UserEntity commenter = userRepository.findByEmail(authorEmail)
                .orElseThrow(() -> new IllegalArgumentException("해당 이메일의 유저를 찾을 수 없습니다: " + authorEmail));

        // 3) 댓글 엔티티 생성 및 저장
        CommentEntity comment = new CommentEntity(
                content,
                LocalDateTime.now(),
                commenter,
                post
        );
        CommentEntity saved = commentRepository.save(comment);

        // 4) 댓글 알림 생성 (자신의 게시물 제외)
        createCommentNotification(post, commenter, content);

        return saved;
    }

    /**
     * 댓글 알림 생성 (자신의 게시물에는 알림 생성하지 않음)
     */
    private void createCommentNotification(PostEntity post, UserEntity commenter, String content) {
        try {
            if (post.getAuthor().getUserId().equals(commenter.getUserId())) {
                // 자신의 게시물에 댓글단 경우 알림 없음
                return;
            }

            // 댓글 내용 미리보기 (50자 제한)
            String preview = content.length() > 50 ? content.substring(0, 50) + "..." : content;

            notificationService.createNotification(
                post.getAuthor().getUserId(),     // 수신자
                commenter.getUserId(),            // 발신자
                NotificationType.COMMENT,         // 타입
                post.getId(),                     // 대상
                commenter.getNickname() + "님이 회원님의 게시물에 댓글을 남겼습니다: '" + preview + "'",
                "/posts/" + post.getId() + "#comments"
            );
        } catch (Exception e) {
            System.err.println("댓글 알림 생성 실패: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /** 게시글에 달린 댓글 목록 조회 */
    public List<CommentEntity> getCommentsForPost(Long postId) {
        PostEntity post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다: " + postId));
        return commentRepository.findByPost(post);
    }

    /** 게시글에 달린 댓글 개수 조회 */
    public long getCommentCount(Long postId) {
        PostEntity post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다: " + postId));
        return commentRepository.countByPost(post);
    }

    /** 단일 댓글 조회 */
    public CommentEntity findById(Long commentId) {
        return commentRepository.findById(commentId)
                .orElseThrow(() -> new IllegalArgumentException("Comment not found with id: " + commentId));
    }

    /** 댓글 삭제 */
    @Transactional
    public void deleteComment(Long commentId, String userEmail) {
        CommentEntity comment = findById(commentId);
        if (!comment.getAuthor().getEmail().equals(userEmail)) {
            throw new IllegalArgumentException("댓글 삭제 권한이 없습니다.");
        }
        commentRepository.delete(comment);
    }

    /** 댓글 수정 */
    @Transactional
    public CommentEntity updateComment(Long commentId, String newContent, String userEmail) {
        CommentEntity comment = findById(commentId);
        if (!comment.getAuthor().getEmail().equals(userEmail)) {
            throw new IllegalArgumentException("댓글 수정 권한이 없습니다.");
        }
        comment.setContent(newContent);
        return commentRepository.save(comment);
    }

    /** 특정 사용자가 작성한 댓글 목록 조회 */
    public List<CommentEntity> getCommentsByUser(String userEmail) {
        UserEntity user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("해당 이메일의 유저를 찾을 수 없습니다: " + userEmail));
        return commentRepository.findByAuthor(user);
    }
}
