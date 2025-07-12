package com.group3.askmyfriend.api;

import com.group3.askmyfriend.entity.CommentEntity;
import com.group3.askmyfriend.entity.LikeEntity;
import com.group3.askmyfriend.entity.PostEntity;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.CommentRepository;
import com.group3.askmyfriend.repository.LikeRepository;
import com.group3.askmyfriend.repository.PostRepository;
import com.group3.askmyfriend.service.UserService;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.data.domain.Sort;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.User;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping(value = "/api/posts", produces = MediaType.APPLICATION_JSON_VALUE + ";charset=UTF-8")
public class PostRestController {

    @Autowired private UserService userService;
    @Autowired private PostRepository postRepository;
    @Autowired private CommentRepository commentRepository;
    @Autowired private LikeRepository likeRepository;

    // 기본 업로드 디렉터리
    private final Path uploadDir = Paths.get("C:/u1 project java/askmyfriend/uploads");
    private final String ffmpegPath = "C:/ffmpeg-7.1.1-essentials_build/bin/ffmpeg.exe";

    /** 현재 로그인한 사용자의 loginId를 꺼내 옵니다. */
    private String currentUserLoginId(@AuthenticationPrincipal User user) {
        return user != null ? user.getUsername() : null;
    }

    /** loginId로 UserEntity 조회(없으면 null) */
    private UserEntity currentUserEntity(@AuthenticationPrincipal User user) {
        if (user == null) return null;
        return userService.findByLoginId(user.getUsername()).orElse(null);
    }

    // ─ Serve uploaded post images/videos ────────────────────────────────────────
    @GetMapping("/image")
    public ResponseEntity<Resource> serveFile(@RequestParam("filename") String filename) {
        return serveResource(uploadDir.resolve(filename), filename);
    }

    // ─ Serve uploaded profile images ────────────────────────────────────────────
    // URL: GET /api/posts/profile-image?filename=xxx.jpg
    @GetMapping("/profile-image")
    public ResponseEntity<Resource> serveProfileImage(@RequestParam("filename") String filename) {
        // 프로필은 uploads/profile 디렉터리 하위에 저장된다고 가정
        Path profileDir = uploadDir.resolve("profile");
        return serveResource(profileDir.resolve(filename), filename);
    }

    // 공통 리소스 서빙 로직
    private ResponseEntity<Resource> serveResource(Path filePath, String rawFilename) {
        try {
            String decoded = URLDecoder.decode(rawFilename, StandardCharsets.UTF_8);
            if (!Files.exists(filePath)) {
                return ResponseEntity.notFound().build();
            }
            Resource resource = new UrlResource(filePath.toUri());
            String contentType = Files.probeContentType(filePath);
            if (contentType == null || "application/octet-stream".equals(contentType)) {
                if (decoded.toLowerCase().endsWith(".mp4")) {
                    contentType = "video/mp4";
                } else if (decoded.matches(".*\\.(jpg|jpeg)$")) {
                    contentType = "image/jpeg";
                } else if (decoded.toLowerCase().endsWith(".png")) {
                    contentType = "image/png";
                }
            }
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + decoded + "\"")
                    .header(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "*")
                    .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(resource);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // ─ List all posts with counts + likedByMe ───────────────────────────────────
    @GetMapping
    public ResponseEntity<List<Map<String,Object>>> listAllPosts(
            @AuthenticationPrincipal User user
    ) {
        String loginId = currentUserLoginId(user);
        UserEntity meEntity = currentUserEntity(user);
        String email = meEntity != null ? meEntity.getEmail() : null;

        List<PostEntity> all = postRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"));
        List<Map<String,Object>> result = all.stream().map(post -> {
            Map<String,Object> m = new HashMap<>();
            m.put("id", post.getId());
            m.put("content", post.getContent());
            m.put("visibility", post.getVisibility());
            m.put("shortForm", post.isShortForm());
            m.put("videoPath", post.getVideoPath());

            String raw = post.getImagePath();
            List<String> imgs = (raw != null && !raw.isEmpty())
                    ? Arrays.asList(raw.split(";"))
                    : Collections.emptyList();
            m.put("imagePaths", imgs);

            if (post.getAuthor() != null) {
                m.put("authorNickname", post.getAuthor().getNickname());
                m.put("authorProfileImg", post.getAuthor().getProfileImg());
            }

            long likeCount    = likeRepository.countByPost(post);
            long commentCount = commentRepository.countByPost(post);
            m.put("likeCount", likeCount);
            m.put("commentCount", commentCount);

            List<String> userEmails = likeRepository.findUserEmailsByPost(post);
            boolean likedByMe = false;
            if (loginId != null && userEmails.contains(loginId)) likedByMe = true;
            if (!likedByMe && email != null && userEmails.contains(email)) likedByMe = true;
            m.put("likedByMe", likedByMe);

            m.put("createdAt", post.getCreatedAt().toString());
            return m;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    // ─ Get a single post with counts, comments + likedByMe ─────────────────────
    @GetMapping("/{postId}")
    public ResponseEntity<Map<String,Object>> getPost(
            @PathVariable Long postId,
            @AuthenticationPrincipal User user
    ) {
        PostEntity post = postRepository.findById(postId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found"));

        String loginId = currentUserLoginId(user);
        UserEntity meEntity = currentUserEntity(user);
        String email = meEntity != null ? meEntity.getEmail() : null;

        Map<String,Object> dto = new HashMap<>();
        dto.put("id", post.getId());
        dto.put("content", post.getContent());
        dto.put("visibility", post.getVisibility());
        dto.put("shortForm", post.isShortForm());
        dto.put("videoPath", post.getVideoPath());

        String rawImages = post.getImagePath();
        List<String> imagePaths = (rawImages != null && !rawImages.isEmpty())
                ? Arrays.asList(rawImages.split(";"))
                : Collections.emptyList();
        dto.put("imagePaths", imagePaths);

        if (post.getAuthor() != null) {
            dto.put("authorNickname", post.getAuthor().getNickname());
            dto.put("authorProfileImg", post.getAuthor().getProfileImg());
        }

        long likeCount    = likeRepository.countByPost(post);
        long commentCount = commentRepository.countByPost(post);
        dto.put("likeCount", likeCount);
        dto.put("commentCount", commentCount);

        List<String> userEmails = likeRepository.findUserEmailsByPost(post);
        boolean likedByMe = false;
        if (loginId != null && userEmails.contains(loginId)) likedByMe = true;
        if (!likedByMe && email != null && userEmails.contains(email)) likedByMe = true;
        dto.put("likedByMe", likedByMe);

        List<Map<String,Object>> comments = commentRepository
            .findByPostOrderByCreatedAtAsc(post)
            .stream()
            .map(c -> {
                Map<String,Object> cm = new HashMap<>();
                cm.put("id", c.getId());
                cm.put("author", c.getAuthor() != null ? c.getAuthor().getNickname() : "Anonymous");
                cm.put("authorProfileImg", c.getAuthor() != null ? c.getAuthor().getProfileImg() : null);
                cm.put("content", c.getContent());
                cm.put("createdAt", c.getCreatedAt().toString());
                return cm;
            }).collect(Collectors.toList());
        dto.put("comments", comments);

        dto.put("createdAt", post.getCreatedAt().toString());
        return ResponseEntity.ok(dto);
    }

    // ─ Like a post ─────────────────────────────────────────────────────────────
    @PostMapping("/{postId}/like")
    @Transactional
    public ResponseEntity<Void> likePost(
            @PathVariable Long postId,
            @AuthenticationPrincipal User user
    ) {
        if (user == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();

        PostEntity post = postRepository.findById(postId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found"));
        String loginId = currentUserLoginId(user);
        UserEntity meEntity = currentUserEntity(user);
        String email = meEntity != null ? meEntity.getEmail() : null;

        // 기존 email 좋아요 제거
        if (email != null && likeRepository.existsByPostAndUserEmail(post, email)) {
            likeRepository.deleteByPostAndUserEmail(post, email);
        }
        // loginId 좋아요 추가
        if (loginId != null && !likeRepository.existsByPostAndUserEmail(post, loginId)) {
            LikeEntity like = new LikeEntity();
            like.setPost(post);
            like.setUserEmail(loginId);
            likeRepository.save(like);
        }
        return ResponseEntity.ok().build();
    }

    // ─ Unlike a post ───────────────────────────────────────────────────────────
    @DeleteMapping("/{postId}/like")
    @Transactional
    public ResponseEntity<Void> unlikePost(
            @PathVariable Long postId,
            @AuthenticationPrincipal User user
    ) {
        if (user == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();

        PostEntity post = postRepository.findById(postId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found"));
        String loginId = currentUserLoginId(user);
        UserEntity meEntity = currentUserEntity(user);
        String email = meEntity
                != null ? meEntity.getEmail() : null;

        if (loginId != null) likeRepository.deleteByPostAndUserEmail(post, loginId);
        if (email   != null) likeRepository.deleteByPostAndUserEmail(post, email);

        return ResponseEntity.ok().build();
    }

    // ─ Add a comment ──────────────────────────────────────────────────────────
    @PostMapping("/{postId}/comments")
    @Transactional
    public ResponseEntity<String> addComment(
            @PathVariable Long postId,
            @RequestBody Map<String,String> payload,
            @AuthenticationPrincipal User user
    ) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인 필요");
        }
        PostEntity post = postRepository.findById(postId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found"));
        UserEntity author = userService.findByLoginId(user.getUsername())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        String content = payload.get("content");
        if (content == null || content.trim().isEmpty()) {
            return ResponseEntity.badRequest().body("댓글 내용을 입력하세요.");
        }

        CommentEntity comment = new CommentEntity();
        comment.setContent(content.trim());
        comment.setCreatedAt(LocalDateTime.now());
        comment.setAuthor(author);
        comment.setPost(post);
        commentRepository.save(comment);

        return ResponseEntity.status(HttpStatus.CREATED).body("댓글 등록 완료");
    }

    // ─ Create text-only post ──────────────────────────────────────────────────
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE,
                 produces = MediaType.TEXT_PLAIN_VALUE + ";charset=UTF-8")
    @Transactional
    public ResponseEntity<String> createTextPost(
            @RequestBody Map<String,Object> payload,
            @AuthenticationPrincipal User user
    ) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Login required");
        }
        UserEntity author = userService.findByLoginId(user.getUsername())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        PostEntity p = new PostEntity();
        p.setContent((String)payload.get("content"));
        p.setVisibility((String)payload.get("visibility"));
        p.setPlatform("MOBILE");
        p.setAccessibility("GENERAL");
        p.setShortForm(Boolean.TRUE.equals(payload.get("shortForm")));
        p.setAuthor(author);
        postRepository.save(p);

        return ResponseEntity.ok("Post created");
    }

    // ─ Upload single image post ──────────────────────────────────────────────
    @PostMapping(value = "/upload",
                 consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
                 produces = MediaType.TEXT_PLAIN_VALUE + ";charset=UTF-8")
    @Transactional
    public ResponseEntity<String> uploadSingleImage(
            @RequestParam("content") String content,
            @RequestParam("visibility") String visibility,
            @RequestParam("shortForm") boolean shortForm,
            @RequestParam(value="image", required=false) MultipartFile image,
            @AuthenticationPrincipal User user
    ) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Login required");
        }
        UserEntity author = userService.findByLoginId(user.getUsername())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        String imagePath = null;
        if (image != null && !image.isEmpty()) {
            try {
                String name = UUID.randomUUID() + "_" + image.getOriginalFilename();
                Files.createDirectories(uploadDir);
                Path path = uploadDir.resolve(name);
                image.transferTo(path.toFile());
                imagePath = "/uploads/" + name;
            } catch (IOException e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Image save failed");
            }
        }

        PostEntity p = new PostEntity();
        p.setContent(content);
        p.setVisibility(visibility);
        p.setPlatform("MOBILE");
        p.setAccessibility("GENERAL");
        p.setShortForm(shortForm);
        p.setImagePath(imagePath);
        p.setAuthor(author);
        postRepository.save(p);

        return ResponseEntity.status(HttpStatus.CREATED).body("Image post uploaded");
    }

    // ─ Upload multiple images & optional video ───────────────────────────────
    @PostMapping(value = "/upload-multiple",
                 consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
                 produces = MediaType.TEXT_PLAIN_VALUE + ";charset=UTF-8")
    @Transactional
    public ResponseEntity<String> uploadMultipleMedia(
            @RequestParam("content") String content,
            @RequestParam("visibility") String visibility,
            @RequestParam("shortForm") boolean shortForm,
            @RequestParam(value="images", required=false) List<MultipartFile> images,
            @RequestParam(value="video",  required=false) MultipartFile video,
            @AuthenticationPrincipal User user
    ) {
        if (user == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Login required");
        }
        UserEntity author = userService.findByLoginId(user.getUsername())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        List<String> paths = new ArrayList<>();
        if (images != null) {
            for (MultipartFile img : images) {
                if (!img.isEmpty()) {
                    try {
                        String name = UUID.randomUUID() + "_" + img.getOriginalFilename();
                        Files.createDirectories(uploadDir);
                        Path p = uploadDir.resolve(name);
                        img.transferTo(p.toFile());
                        paths.add("/uploads/" + name);
                    } catch (IOException e) {
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                             .body("Image save failed: " + e.getMessage());
                    }
                }
            }
        }

        String videoPath = null;
        if (video != null && !video.isEmpty()) {
            try {
                String name = UUID.randomUUID() + "_" + video.getOriginalFilename();
                Files.createDirectories(uploadDir);
                Path source = uploadDir.resolve(name);
                video.transferTo(source.toFile());

                String outName = "encoded_" + name;
                Path target = uploadDir.resolve(outName);
                new ProcessBuilder(
                    ffmpegPath, "-i", source.toString(),
                    "-vcodec", "libx264", "-acodec", "aac", "-movflags", "+faststart",
                    target.toString()
                ).inheritIO().start().waitFor();

                videoPath = "/uploads/" + outName;
            } catch (IOException | InterruptedException e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                     .body("Video save failed: " + e.getMessage());
            }
        }

        PostEntity p = new PostEntity();
        p.setContent(content);
        p.setVisibility(visibility);
        p.setPlatform("MOBILE");
        p.setAccessibility("GENERAL");
        p.setShortForm(shortForm);
        p.setImagePath(String.join(";", paths));
        p.setVideoPath(videoPath);
        p.setAuthor(author);
        postRepository.save(p);

        return ResponseEntity.status(HttpStatus.CREATED).body("Media post uploaded");
    }
}
