package mx.edu.utez.sruu.user;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/** Perfil propio (HU-04) y gestión de cuentas del Administrador (HU-24/25). */
@RestController
class UserController {

    record UpdateProfile(
            @Size(max = 120, message = "Usa máximo 120 caracteres.") String fullName,
            @Size(max = 20, message = "Usa máximo 20 caracteres.")
            @Pattern(regexp = "^[0-9+()\\-\\s]*$", message = "Usa solo números en el teléfono.")
            String phone) {}

    /** {@code reason} documenta la sanción (RN-03); la bitácora vive en la Épica 5. */
    record SetPermission(
            @NotNull ManagedPermission permission,
            @NotNull Boolean active,
            @Size(max = 500) String reason) {}

    private final UserService service;

    UserController(UserService service) {
        this.service = service;
    }

    @PatchMapping("/users/me")
    UserResponse updateMe(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody UpdateProfile body) {
        return UserResponse.of(service.updateProfile(subject(jwt), body.fullName(), body.phone()));
    }

    @GetMapping("/admin/users")
    List<UserResponse> list(@AuthenticationPrincipal Jwt jwt) {
        return service.listUsers(subject(jwt)).stream().map(UserResponse::of).toList();
    }

    @PatchMapping("/admin/users/{id}/permissions")
    UserResponse setPermission(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id,
            @Valid @RequestBody SetPermission body) {
        return UserResponse.of(service.setPermission(subject(jwt), id, body.permission(), body.active()));
    }

    private static UUID subject(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
