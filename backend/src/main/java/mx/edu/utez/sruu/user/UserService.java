package mx.edu.utez.sruu.user;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import mx.edu.utez.sruu.common.ApiException;

/** Perfil (HU-04) y administración de permisos por cuenta (HU-05, HU-24/25). */
@Service
public class UserService {

    private final UserRepository users;

    public UserService(UserRepository users) {
        this.users = users;
    }

    // ---------- HU-04 ----------

    /**
     * Edita solo datos de contacto; el correo institucional no cambia.
     * Un perfil restringido (sin Rentador ni Vendedor) es de solo lectura.
     */
    @Transactional
    public User updateProfile(UUID userId, String fullName, String phone) {
        final User user = load(userId);
        if (user.isRestricted()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "PROFILE_READ_ONLY",
                    "Tu perfil está en modo solo lectura: no tienes permisos de Rentador ni Vendedor activos.");
        }
        final String name = fullName == null ? null : fullName.trim();
        if (name != null && name.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", "Ingresa tu nombre.");
        }
        user.updateContact(name, phone == null ? null : phone.trim());
        return user;
    }

    // ---------- Administración (HU-24/25) ----------

    @Transactional(readOnly = true)
    public List<User> listUsers(UUID adminId) {
        requireAdmin(adminId);
        return users.findAll().stream()
                .sorted(Comparator.comparing(User::getFullName, String.CASE_INSENSITIVE_ORDER))
                .toList();
    }

    /** Suspende o reactiva un permiso sin afectar al otro (RN-02). */
    @Transactional
    public User setPermission(UUID adminId, UUID targetId, ManagedPermission permission, boolean active) {
        requireAdmin(adminId);
        final User target = users.findById(targetId).orElseThrow(() ->
                new ApiException(HttpStatus.NOT_FOUND, "USER_NOT_FOUND", "No existe esa cuenta."));
        target.setPermission(permission, active);
        return target;
    }

    // ---------- helpers ----------

    private User load(UUID userId) {
        return users.findById(userId).orElseThrow(() ->
                new ApiException(HttpStatus.UNAUTHORIZED, "SESSION_INVALID", "La sesión ya no es válida."));
    }

    /** Los permisos se validan en el servidor, no solo en la interfaz (HU-05). */
    private void requireAdmin(UUID userId) {
        if (!load(userId).isAdmin()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", "No tienes permiso para esta acción.");
        }
    }
}
