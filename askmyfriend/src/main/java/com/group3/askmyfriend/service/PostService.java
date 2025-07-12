// ✅ PostService.java (PostImageEntity 사용 제거, PostEntity.imagePath로만 저장)
package com.group3.askmyfriend.service;

import com.group3.askmyfriend.dto.CommentDto;
import com.group3.askmyfriend.dto.PostDto;
import com.group3.askmyfriend.entity.PostEntity;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.PostRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.security.Principal;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class PostService {

    private final PostRepository postRepository;
    private final ShortFormSelector shortFormSelector;

    @Autowired
    private UserService userService;

    @Autowired
    public PostService(PostRepository postRepository,
                       @Qualifier("randomShortFormSelector") ShortFormSelector shortFormSelector) {
        this.postRepository = postRepository;
        this.shortFormSelector = shortFormSelector;
    }

    public PostEntity findById(Long id) {
        return postRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Post not found with id: " + id));
    }

    public void createPost(PostDto dto,
                           MultipartFile imageFile,
                           MultipartFile videoFile,
                           Principal principal) throws IOException {

        PostEntity entity = new PostEntity();
        entity.setContent(dto.getContent());
        entity.setVisibility(dto.getVisibility());
        entity.setPlatform(dto.getPlatform());
        entity.setAccessibility(dto.getAccessibility());
        entity.setShortForm(Boolean.TRUE.equals(dto.getShortForm()));

        if (principal != null) {
            UserEntity currentUser = userService.findByLoginId(principal.getName()).orElse(null);
            if (currentUser != null) {
                entity.setAuthor(currentUser);
            }
        }

        if (imageFile != null && !imageFile.isEmpty()) {
            String imagePath = saveImage(imageFile);
            entity.setImagePath(imagePath);
        }

        if (videoFile != null && !videoFile.isEmpty()) {
            String videoPath = saveVideo(videoFile);
            entity.setVideoPath(videoPath);
        }

        postRepository.save(entity);
    }

    public void createPost(PostDto dto,
                           MultipartFile imageFile,
                           MultipartFile videoFile) throws IOException {

        PostEntity entity = new PostEntity();
        entity.setContent(dto.getContent());
        entity.setVisibility(dto.getVisibility());
        entity.setPlatform(dto.getPlatform());
        entity.setAccessibility(dto.getAccessibility());
        entity.setShortForm(Boolean.TRUE.equals(dto.getShortForm()));

        if (imageFile != null && !imageFile.isEmpty()) {
            String imagePath = saveImage(imageFile);
            entity.setImagePath(imagePath);
        }

        if (videoFile != null && !videoFile.isEmpty()) {
            String videoPath = saveVideo(videoFile);
            entity.setVideoPath(videoPath);
        }

        postRepository.save(entity);
    }

    private String saveImage(MultipartFile file) throws IOException {
        String uploadDir = "uploads";
        String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path dirPath = Paths.get(uploadDir);
        Files.createDirectories(dirPath);
        Path filePath = dirPath.resolve(fileName);
        Files.write(filePath, file.getBytes(), StandardOpenOption.CREATE);
        return "/uploads/" + fileName.replace("\\", "/");
    }

    private String saveVideo(MultipartFile file) throws IOException {
        String uploadDir = "uploads";
        String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path dirPath = Paths.get(uploadDir);
        Files.createDirectories(dirPath);
        Path filePath = dirPath.resolve(fileName);
        Files.write(filePath, file.getBytes(), StandardOpenOption.CREATE);
        return "/uploads/" + fileName.replace("\\", "/");
    }

    public List<PostEntity> getAllPosts() {
        return postRepository.findAll();
    }

    public List<PostEntity> findAllPosts(Sort sort) {
        return postRepository.findAll(sort);
    }

    public List<PostDto> findAllPostDtos(Sort sort) {
        List<PostEntity> posts = postRepository.findAll(sort);
        return posts.stream().map(post -> {
            PostDto dto = new PostDto();
            dto.setId(post.getId());
            dto.setContent(post.getContent());
            dto.setVisibility(post.getVisibility());
            dto.setPlatform(post.getPlatform());
            dto.setAccessibility(post.getAccessibility());
            dto.setImagePath(post.getImagePath());
            dto.setVideoPath(post.getVideoPath());
            dto.setShortForm(post.isShortForm());
            dto.setLikeCount(post.getLikes().size());
            dto.setCommentCount(post.getComments().size());

            List<CommentDto> commentDtos = post.getComments().stream()
                .map(comment -> {
                    CommentDto cdto = new CommentDto();
                    cdto.setId(comment.getId());
                    cdto.setPostId(post.getId());
                    cdto.setContent(comment.getContent());
                    cdto.setCreatedAt(comment.getCreatedAt());
                    cdto.setAuthor(comment.getAuthor() != null ? comment.getAuthor().getNickname() : "알 수 없음");
                    return cdto;
                })
                .collect(Collectors.toList());

            dto.setComments(commentDtos);
            return dto;
        }).collect(Collectors.toList());
    }

    public PostDto getShortForm() {
        List<PostEntity> candidates = postRepository.findByShortFormTrue();
        PostEntity picked = shortFormSelector.selectNext(candidates);
        return toDto(picked);
    }

    private PostDto toDto(PostEntity post) {
        if (post == null) return null;
        PostDto dto = new PostDto();
        dto.setId(post.getId());
        dto.setContent(post.getContent());
        dto.setVideoPath(post.getVideoPath());
        dto.setShortForm(post.isShortForm());
        dto.setLikeCount(post.getLikes() != null ? post.getLikes().size() : 0);
        dto.setCommentCount(post.getComments() != null ? post.getComments().size() : 0);
        return dto;
    }
}
