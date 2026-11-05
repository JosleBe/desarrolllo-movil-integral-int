package mx.edu.utez.sruu.auth;

import java.util.Map;
import java.util.UUID;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import mx.edu.utez.sruu.user.UserResponse;

/** Contrato de la Épica 1; ver app/docs/auth-api.md. */
@RestController
@RequestMapping("/auth")
class AuthController {

    private final AuthService auth;

    AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    Map<String, UserResponse> register(@Valid @RequestBody AuthRequests.Register body) {
        return Map.of("user", UserResponse.of(auth.register(body.fullName(), body.email(), body.password())));
    }

    @PostMapping("/verify")
    Map<String, UserResponse> verify(@Valid @RequestBody AuthRequests.Verify body) {
        return Map.of("user", UserResponse.of(auth.verify(body.email(), body.code())));
    }

    @PostMapping("/verify/resend")
    @ResponseStatus(HttpStatus.ACCEPTED)
    void resend(@Valid @RequestBody AuthRequests.Resend body) {
        auth.resend(body.email());
    }

    record LoginResponse(String accessToken, String expiresAt, UserResponse user) {}

    @PostMapping("/login")
    LoginResponse login(@Valid @RequestBody AuthRequests.Login body) {
        final AuthService.Session session = auth.login(body.email(), body.password());
        return new LoginResponse(session.accessToken(), session.expiresAt().toString(),
                UserResponse.of(session.user()));
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void logout(@AuthenticationPrincipal Jwt jwt) {
        auth.logout(jwt.getId(), jwt.getExpiresAt());
    }

    @GetMapping("/me")
    UserResponse me(@AuthenticationPrincipal Jwt jwt) {
        return UserResponse.of(auth.currentUser(UUID.fromString(jwt.getSubject())));
    }
}
