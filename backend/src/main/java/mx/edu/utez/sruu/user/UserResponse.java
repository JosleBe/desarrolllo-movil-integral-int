package mx.edu.utez.sruu.user;

import java.util.UUID;

/** Forma pública del usuario; nunca incluye el hash de la contraseña. */
public record UserResponse(
        UUID id,
        String email,
        String fullName,
        String phone,
        AccountStatus status,
        UserRole role,
        Permissions permissions) {

    /** Matriz de permisos de la cuenta (la app la lee como {@code UserPermissions}). */
    public record Permissions(boolean renter, boolean seller, boolean reception, boolean admin) {}

    public static UserResponse of(User user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getPhone(),
                user.getStatus(),
                user.getRole(),
                new Permissions(user.isRenter(), user.isSeller(), user.isReception(), user.isAdmin()));
    }
}
