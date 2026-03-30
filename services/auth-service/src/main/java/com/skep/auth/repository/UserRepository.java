package com.skep.auth.repository;

import com.skep.auth.domain.entity.User;
import com.skep.auth.domain.enums.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmail(String email);

    Optional<User> findByEmailAndStatus(String email, User.UserStatus status);

    List<User> findByCompanyIdAndStatus(UUID companyId, User.UserStatus status);

    List<User> findByRole(UserRole role);

    List<User> findByCompanyId(UUID companyId);

    @Query("SELECT u FROM User u WHERE u.email = :email AND u.status = 'ACTIVE'")
    Optional<User> findActiveUserByEmail(@Param("email") String email);

    @Query("SELECT COUNT(u) FROM User u WHERE u.email = :email")
    long countByEmail(@Param("email") String email);

    @Query("SELECT u FROM User u WHERE u.id = :userId AND u.status = 'ACTIVE'")
    Optional<User> findActiveUserById(@Param("userId") UUID userId);

    List<User> findByStatusAndRole(User.UserStatus status, UserRole role);
}
