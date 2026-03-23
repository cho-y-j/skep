package com.skep.documentservice.util;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Slf4j
@Component
public class S3FileUploader {

    private static final String UPLOAD_DIR = "/tmp/skep-uploads";

    public S3FileUploader() {
        // 업로드 디렉토리 생성
        try {
            Files.createDirectories(Paths.get(UPLOAD_DIR));
        } catch (IOException e) {
            log.warn("Failed to create upload directory: {}", UPLOAD_DIR);
        }
    }

    public String uploadFile(MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }

        String key = generateKey(file.getOriginalFilename());
        Path filePath = Paths.get(UPLOAD_DIR, key);
        Files.createDirectories(filePath.getParent());
        file.transferTo(filePath.toFile());

        log.info("File saved locally: {}", filePath);
        return "/uploads/" + key;
    }

    private String generateKey(String originalFilename) {
        String timestamp = System.currentTimeMillis() + "";
        String uuid = UUID.randomUUID().toString().substring(0, 8);
        String extension = getFileExtension(originalFilename);
        return timestamp + "_" + uuid + "." + extension;
    }

    private String getFileExtension(String filename) {
        if (filename == null || !filename.contains(".")) return "bin";
        return filename.substring(filename.lastIndexOf(".") + 1).toLowerCase();
    }

    public void deleteFile(String fileUrl) {
        try {
            if (fileUrl != null && fileUrl.startsWith("/uploads/")) {
                Path path = Paths.get(UPLOAD_DIR, fileUrl.replace("/uploads/", ""));
                Files.deleteIfExists(path);
                log.info("File deleted: {}", path);
            }
        } catch (Exception e) {
            log.error("Failed to delete file: {}", fileUrl, e);
        }
    }
}
