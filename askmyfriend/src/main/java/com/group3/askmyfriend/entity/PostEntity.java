package com.group3.askmyfriend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "posts")
public class PostEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String content;
    private String visibility;
    private String platform;
    private String accessibility;
    @Column(name = "image_path", columnDefinition = "TEXT")
    private String imagePath;

    private String videoPath;

    private int likeCount;

    @Column(nullable = false)
    private boolean shortForm = false;

    @Column(updatable = false)
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id")
    private UserEntity author;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<CommentEntity> comments = new ArrayList<>();

    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<LikeEntity> likes = new ArrayList<>();

    @Transient
    private int commentCount;

    /**
     * ❌ 더 이상 사용되지 않음 - PostImageEntity는 보류 상태이며, 이미지 경로는 imagePath 문자열로 관리됨
     * 참고용으로만 유지
     */
//    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true)
//    private List<PostImageEntity> images = new ArrayList<>();

//    public List<PostImageEntity> getImages() { return images; }
//    public void setImages(List<PostImageEntity> images) {
//        this.images = images;
//        if (images != null) {
//            for (PostImageEntity img : images) {
//                img.setPost(this);
//            }
//        }
//    }

    // ───── Getter & Setter ─────

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getVisibility() { return visibility; }
    public void setVisibility(String visibility) { this.visibility = visibility; }

    public String getPlatform() { return platform; }
    public void setPlatform(String platform) { this.platform = platform; }

    public String getAccessibility() { return accessibility; }
    public void setAccessibility(String accessibility) { this.accessibility = accessibility; }

    public String getImagePath() { return imagePath; }
    public void setImagePath(String imagePath) { this.imagePath = imagePath; }

    public String getVideoPath() { return videoPath; }
    public void setVideoPath(String videoPath) { this.videoPath = videoPath; }

    public int getLikeCount() { return likeCount; }
    public void setLikeCount(int likeCount) { this.likeCount = likeCount; }

    public LocalDateTime getCreatedAt() { return createdAt; }

    public boolean isShortForm() { return shortForm; }
    public void setShortForm(boolean shortForm) { this.shortForm = shortForm; }

    public UserEntity getAuthor() { return author; }
    public void setAuthor(UserEntity author) { this.author = author; }

    public List<CommentEntity> getComments() { return comments; }
    public void setComments(List<CommentEntity> comments) { this.comments = comments; }

    public List<LikeEntity> getLikes() { return likes; }
    public void setLikes(List<LikeEntity> likes) { this.likes = likes; }

    public int getCommentCount() { return commentCount; }
    public void setCommentCount(int commentCount) { this.commentCount = commentCount; }
} 
