package mx.edu.utez.sruu.user;

import java.util.UUID;

/** Forma pública del usuario; nunca incluye el hash de la contraseña. */
public record UserResponse(UUID id, String email, String fullName, AccountStatus status, UserRole role) {

    public static UserResponse of(User user) {
        return new UserResponse(
                user.getId(), user.getEmail(), user.getFullName(), user.getStatus(), user.getRole());
    }
}
