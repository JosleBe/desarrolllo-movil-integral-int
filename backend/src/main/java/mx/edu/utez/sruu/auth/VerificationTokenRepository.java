package mx.edu.utez.sruu.auth;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

interface VerificationTokenRepository extends JpaRepository<VerificationToken, UUID> {

    @Query("select t from VerificationToken t where t.user.id = :userId order by t.createdAt desc")
    List<VerificationToken> findByUserNewestFirst(UUID userId);
}
