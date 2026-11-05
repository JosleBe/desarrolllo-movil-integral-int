package mx.edu.utez.sruu.user;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "users")
public class User {

    @Id
    private UUID id;

    @Column(nullable = false, length = 254)
    private String email;

    @Column(name = "full_name", nullable = false, length = 120)
    private String fullName;

    /** Hash BCrypt; la contraseña en claro nunca se persiste. */
    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private AccountStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private UserRole role;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    protected User() {}

    public static User pending(String email, String fullName, String passwordHash, Instant now) {
        final User user = new User();
        user.id = UUID.randomUUID();
        user.email = email;
        user.fullName = fullName;
        user.passwordHash = passwordHash;
        user.status = AccountStatus.PENDIENTE_VERIFICACION;
        user.role = UserRole.NINGUNO;
        user.createdAt = now;
        return user;
    }

    /** HU-02: al verificar el correo la cuenta recibe el rol Usuario Base. */
    public void markVerified(Instant now) {
        this.status = AccountStatus.VERIFICADA;
        this.role = UserRole.USUARIO_BASE;
        this.verifiedAt = now;
    }

    public boolean isVerified() {
        return status == AccountStatus.VERIFICADA;
    }

    public UUID getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getFullName() {
        return fullName;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public AccountStatus getStatus() {
        return status;
    }

    public UserRole getRole() {
        return role;
    }
}
