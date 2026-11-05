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

    /** Dato de contacto editable (HU-04). */
    @Column(length = 20)
    private String phone;

    /** Permiso de Rentador: buscar y solicitar útiles. */
    @Column(name = "perm_renter", nullable = false)
    private boolean renter;

    /** Permiso de Vendedor: publicar útiles. Independiente de {@link #renter} (RN-02). */
    @Column(name = "perm_seller", nullable = false)
    private boolean seller;

    /** Rol operativo de Recepción (Épica 4). */
    @Column(name = "perm_reception", nullable = false)
    private boolean reception;

    /** Rol de Administrador (Épica 5). */
    @Column(name = "perm_admin", nullable = false)
    private boolean admin;

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

    /** Sin Rentador ni Vendedor: perfil restringido de solo lectura (HU-04). */
    public boolean isRestricted() {
        return !renter && !seller;
    }

    /** HU-04: el correo institucional nunca cambia; solo nombre y teléfono. */
    public void updateContact(String fullName, String phone) {
        if (fullName != null) {
            this.fullName = fullName;
        }
        if (phone != null) {
            this.phone = phone.isBlank() ? null : phone;
        }
    }

    /** Cambia un solo permiso sin tocar el otro (RN-02). */
    public void setPermission(ManagedPermission permission, boolean active) {
        switch (permission) {
            case RENTER -> this.renter = active;
            case SELLER -> this.seller = active;
        }
    }

    /** Solo para datos de demostración y pruebas. */
    public void setPermissions(boolean renter, boolean seller, boolean reception, boolean admin) {
        this.renter = renter;
        this.seller = seller;
        this.reception = reception;
        this.admin = admin;
    }

    /** Solo para datos de demostración. */
    public void replacePasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
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

    public String getPhone() {
        return phone;
    }

    public boolean isRenter() {
        return renter;
    }

    public boolean isSeller() {
        return seller;
    }

    public boolean isReception() {
        return reception;
    }

    public boolean isAdmin() {
        return admin;
    }
}
