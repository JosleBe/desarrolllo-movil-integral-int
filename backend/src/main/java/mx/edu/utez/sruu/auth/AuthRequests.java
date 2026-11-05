package mx.edu.utez.sruu.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

final class AuthRequests {

    private AuthRequests() {}

    record Register(
            @NotBlank(message = "Ingresa tu nombre.")
            @Size(max = 120, message = "Usa máximo 120 caracteres.")
            String fullName,
            @NotBlank(message = "Falta tu correo institucional.") String email,
            @NotBlank(message = "Falta tu clave.") String password) {}

    record Login(@NotBlank String email, @NotBlank String password) {}

    /** HU-02: el código de 6 dígitos que llegó al correo de esa cuenta. */
    record Verify(@NotBlank String email, @NotBlank String code) {}

    record Resend(@NotBlank String email) {}
}
