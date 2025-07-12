package com.group3.askmyfriend.repository;

import com.group3.askmyfriend.entity.CommentEntity;
import com.group3.askmyfriend.entity.PostEntity;
import com.group3.askmyfriend.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface CommentRepository extends JpaRepository<CommentEntity, Long> {

    // 게시물에 달린 댓글 조회
    List<CommentEntity> findByPost(PostEntity post);

    // 사용자 기준 댓글 조회
    List<CommentEntity> findByAuthor(UserEntity author);

    // 게시물 기준 댓글 수
    long countByPost(PostEntity post);

    // 댓글 정렬 조회
    List<CommentEntity> findByPostOrderByCreatedAtAsc(PostEntity post);
    List<CommentEntity> findByPostOrderByCreatedAtDesc(PostEntity post);
    List<CommentEntity> findByAuthorOrderByCreatedAtDesc(UserEntity author);

    // 삭제
    void deleteByPost(PostEntity post);
    void deleteByAuthor(UserEntity author);

    // ▶ 로그인ID(loginId) 기준으로 댓글 단 게시물 조회 (중복 제거 + 최신순)
    @Query("""
        SELECT DISTINCT c.post
          FROM CommentEntity c
         WHERE c.author.loginId = :loginId
      ORDER BY c.post.createdAt DESC
    """)
    List<PostEntity> findDistinctPostsByAuthorLoginIdOrderByPostCreatedAtDesc(
        @Param("loginId") String loginId
    );

    // 특정 게시물에 댓글 단 유저 목록
    @Query("""
        SELECT DISTINCT c.author
          FROM CommentEntity c
         WHERE c.post = :post
    """)
    List<UserEntity> findDistinctAuthorsByPost(@Param("post") PostEntity post);

    // 특정 사용자의 댓글 수
    long countByAuthor(UserEntity author);

    // 특정 기간 이후 작성된 댓글 (작성일자 기준 최신순)
    @Query("""
        SELECT c
          FROM CommentEntity c
         WHERE c.author = :author
           AND c.createdAt >= :startDate
      ORDER BY c.createdAt DESC
    """)
    List<CommentEntity> findByAuthorAndCreatedAtAfterOrderByCreatedAtDesc(
        @Param("author") UserEntity author,
        @Param("startDate") LocalDateTime startDate
    );
}
