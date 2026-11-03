package mx.edu.utez.sruu.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

final class AuthRequests {

    private AuthRequests() {}

    record Register(
            @NotBlank(message = "Falta tu nombre.")
            @Size(min = 3, max = 120, message = "Escribe tu nombre completo.")
            String fullName,
            @NotBlank(message = "Falta tu correo institucional.") String email,
            @NotBlank(message = "Falta tu clave.") String password) {}

    record Login(@NotBlank String email, @NotBlank String password) {}

    record Verify(@NotBlank String token) {}

    record Resend(@NotBlank String email) {}
}
