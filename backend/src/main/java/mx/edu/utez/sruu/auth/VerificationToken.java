package mx.edu.utez.sruu.auth;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import mx.edu.utez.sruu.user.User;

@Entity
@Table(name = "verification_tokens")
public class VerificationToken {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    /** SHA-256 de {@code <id de usuario>:<código>}; el código en claro solo viaja en el correo. */
    @Column(name = "token_hash", nullable = false, length = 64)
    private String tokenHash;

    @Column(name = "failed_attempts", nullable = false)
    private int failedAttempts;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "used_at")
    private Instant usedAt;

    @Column(name = "revoked_at")
    private Instant revokedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected VerificationToken() {}

    static VerificationToken issue(User user, String tokenHash, Instant now, Instant expiresAt) {
        final VerificationToken t = new VerificationToken();
        t.id = UUID.randomUUID();
        t.user = user;
        t.tokenHash = tokenHash;
        t.createdAt = now;
        t.expiresAt = expiresAt;
        return t;
    }

    /** Usado o reemplazado por un reenvío: ya no sirve. */
    boolean isConsumed() {
        return usedAt != null || revokedAt != null;
    }

    boolean isExpiredAt(Instant now) {
        return !now.isBefore(expiresAt);
    }

    /** Comparación en tiempo constante para no filtrar información por tiempos. */
    boolean matches(String candidateHash) {
        return java.security.MessageDigest.isEqual(
                tokenHash.getBytes(java.nio.charset.StandardCharsets.US_ASCII),
                candidateHash.getBytes(java.nio.charset.StandardCharsets.US_ASCII));
    }

    boolean isLocked(int maxAttempts) {
        return failedAttempts >= maxAttempts;
    }

    /** Cuenta un intento fallido; al llegar al límite el código deja de servir. */
    void registerFailedAttempt(int maxAttempts, Instant now) {
        failedAttempts++;
        if (failedAttempts >= maxAttempts) {
            revoke(now);
        }
    }

    void markUsed(Instant now) {
        this.usedAt = now;
    }

    void revoke(Instant now) {
        if (usedAt == null && revokedAt == null) {
            this.revokedAt = now;
        }
    }

    User getUser() {
        return user;
    }

    Instant getCreatedAt() {
        return createdAt;
    }
}
