package com.group3.askmyfriend.entity;

import jakarta.persistence.*;

/**
 * ❌ [보류] 더 이상 사용되지 않음.
 * ✅ 이미지 경로는 PostEntity.imagePath에 문자열로 저장함.
 * 이 클래스는 추후 확장 목적 또는 이력 보존용으로 남겨둠.
 */
@Deprecated
@Entity
@Table(name = "post_images")
public class PostImageEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String path;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    private PostEntity post;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getPath() { return path; }
    public void setPath(String path) { this.path = path; }

    public PostEntity getPost() { return post; }
    public void setPost(PostEntity post) { this.post = post; }
}
