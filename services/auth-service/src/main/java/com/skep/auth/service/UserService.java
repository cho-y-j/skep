package com.skep.auth.service;

import com.skep.auth.domain.entity.FingerprintTemplate;
import com.skep.auth.domain.entity.User;
import com.skep.auth.repository.FingerprintTemplateRepository;
import com.skep.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class UserService {

    private final UserRepository userRepository;
    private final FingerprintTemplateRepository fingerprintTemplateRepository;

    public void registerFingerprint(UUID userId, byte[] template, Integer fingerIndex) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // 이미 등록된 손가락이 있는지 확인
        if (fingerprintTemplateRepository.findByUserIdAndFingerIndex(userId, fingerIndex).isPresent()) {
            throw new IllegalArgumentException("Fingerprint already registered for this finger index");
        }

        FingerprintTemplate fingerprintTemplate = FingerprintTemplate.builder()
                .user(user)
                .template(template)
                .fingerIndex(fingerIndex)
                .build();

        fingerprintTemplateRepository.save(fingerprintTemplate);
        log.info("Fingerprint registered for user: {}, finger index: {}", userId, fingerIndex);
    }

    public List<FingerprintTemplate> getUserFingerprints(UUID userId) {
        return fingerprintTemplateRepository.findByUserIdOrderByFingerIndex(userId);
    }

    public long getFingerprintCount(UUID userId) {
        return fingerprintTemplateRepository.countByUserId(userId);
    }

    public void deleteFingerprint(UUID fingerprintId) {
        fingerprintTemplateRepository.deleteById(fingerprintId);
        log.info("Fingerprint deleted: {}", fingerprintId);
    }

    public void deleteAllFingerprintsByUserId(UUID userId) {
        fingerprintTemplateRepository.deleteByUserId(userId);
        log.info("All fingerprints deleted for user: {}", userId);
    }

    public void updateUserStatus(UUID userId, User.UserStatus status) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        user.setStatus(status);
        user.setUpdatedBy(userId);
        userRepository.save(user);
        log.info("User status updated to {} for user: {}", status, userId);
    }

    @Transactional(readOnly = true)
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public User getUserById(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    public User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }
}
