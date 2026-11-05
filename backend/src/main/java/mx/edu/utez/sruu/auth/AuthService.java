package mx.edu.utez.sruu.auth;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Map;
import java.util.UUID;

import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import mx.edu.utez.sruu.common.ApiException;
import mx.edu.utez.sruu.config.SruuProperties;
import mx.edu.utez.sruu.user.User;
import mx.edu.utez.sruu.user.UserRepository;

@Service
class AuthService {

    record Session(String accessToken, Instant expiresAt, User user) {}

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository users;
    private final VerificationTokenRepository verificationTokens;
    private final RevokedTokenRepository revokedTokens;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;
    private final ApplicationEventPublisher events;
    private final SruuProperties props;
    private final Clock clock;

    /** Hash de referencia para igualar el tiempo de respuesta con correos inexistentes. */
    private final String dummyHash;

    AuthService(
            UserRepository users,
            VerificationTokenRepository verificationTokens,
            RevokedTokenRepository revokedTokens,
            PasswordEncoder passwordEncoder,
            TokenService tokenService,
            ApplicationEventPublisher events,
            SruuProperties props,
            Clock clock) {
        this.users = users;
        this.verificationTokens = verificationTokens;
        this.revokedTokens = revokedTokens;
        this.passwordEncoder = passwordEncoder;
        this.tokenService = tokenService;
        this.events = events;
        this.props = props;
        this.clock = clock;
        this.dummyHash = passwordEncoder.encode("dummy-password-for-timing");
    }

    // ---------- HU-01 ----------

    @Transactional
    User register(String fullName, String rawEmail, String password) {
        final String email = InstitutionalEmail.normalize(rawEmail);
        if (!InstitutionalEmail.isValid(email)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_CONTENT, "INSTITUTIONAL_EMAIL_REQUIRED",
                    "Solo se aceptan correos @utez.edu.mx.");
        }
        if (!PasswordPolicy.isAcceptable(password)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "WEAK_PASSWORD",
                    "La clave necesita 8 caracteres o más, mayúscula, minúscula y un número.");
        }
        if (users.existsByEmailIgnoreCase(email)) {
            throw emailTaken();
        }
        final User user = User.pending(email, fullName.trim(), passwordEncoder.encode(password), clock.instant());
        try {
            users.saveAndFlush(user);
        } catch (DataIntegrityViolationException e) {
            throw emailTaken(); // carrera entre dos registros simultáneos
        }
        issueVerification(user);
        return user;
    }

    // ---------- HU-02 ----------

    @Transactional(noRollbackFor = ApiException.class)
    User verify(String token) {
        final VerificationToken record = verificationTokens.findByTokenHash(sha256(token))
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "TOKEN_INVALID",
                        "El enlace no es válido."));
        final User user = record.getUser();
        final Map<String, Object> email = Map.of("email", user.getEmail());
        if (record.isConsumed()) {
            throw new ApiException(HttpStatus.CONFLICT, "TOKEN_ALREADY_USED", "Este enlace ya se usó.", email);
        }
        final Instant now = clock.instant();
        if (record.isExpiredAt(now)) {
            throw new ApiException(HttpStatus.GONE, "TOKEN_EXPIRED", "Este enlace venció.", email);
        }
        record.markUsed(now);
        user.markVerified(now);
        return user;
    }

    /**
     * Responde igual exista o no la cuenta (no revela correos registrados).
     * Invalida los enlaces anteriores y respeta un tiempo de espera.
     */
    @Transactional
    void resend(String rawEmail) {
        final String email = InstitutionalEmail.normalize(rawEmail);
        final User user = users.findByEmailIgnoreCase(email).orElse(null);
        if (user == null || user.isVerified()) {
            return;
        }
        final var existing = verificationTokens.findByUserNewestFirst(user.getId());
        final Instant now = clock.instant();
        final Duration cooldown = props.verification().resendCooldown();
        if (!existing.isEmpty() && Duration.between(existing.getFirst().getCreatedAt(), now).compareTo(cooldown) < 0) {
            throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMITED",
                    "Ya te mandamos un enlace hace poco. Espera un minuto.");
        }
        existing.forEach(t -> t.revoke(now));
        issueVerification(user);
    }

    // ---------- HU-03 ----------

    @Transactional(readOnly = true)
    Session login(String rawEmail, String password) {
        final User user = users.findByEmailIgnoreCase(InstitutionalEmail.normalize(rawEmail)).orElse(null);
        final boolean matches = passwordEncoder.matches(password, user == null ? dummyHash : user.getPasswordHash());
        if (user == null || !matches) {
            // Mismo código y mensaje para correo inexistente y contraseña incorrecta.
            throw new ApiException(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS", "Correo o contraseña incorrectos.");
        }
        if (!user.isVerified()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "EMAIL_NOT_VERIFIED",
                    "Tu cuenta aún no está verificada.", Map.of("email", user.getEmail()));
        }
        final TokenService.IssuedToken token = tokenService.issue(user);
        return new Session(token.value(), token.expiresAt(), user);
    }

    @Transactional
    void logout(String jti, Instant expiresAt) {
        if (jti != null && !revokedTokens.existsById(jti)) {
            revokedTokens.save(new RevokedToken(jti, expiresAt));
        }
    }

    @Transactional(readOnly = true)
    User currentUser(UUID userId) {
        return users.findById(userId).orElseThrow(() ->
                new ApiException(HttpStatus.UNAUTHORIZED, "SESSION_INVALID", "La sesión ya no es válida."));
    }

    /** Las entradas vencidas ya no hacen falta: el JWT expiró por sí solo. */
    @Scheduled(cron = "0 15 3 * * *")
    void purgeExpiredRevocations() {
        revokedTokens.deleteExpired(clock.instant());
    }

    // ---------- helpers ----------

    private void issueVerification(User user) {
        final byte[] bytes = new byte[32]; // 256 bits
        RANDOM.nextBytes(bytes);
        final String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        final Instant now = clock.instant();
        verificationTokens.save(VerificationToken.issue(
                user, sha256(token), now, now.plus(props.verification().ttl())));
        events.publishEvent(new VerificationRequested(user.getEmail(), user.getFullName(), token));
    }

    private static ApiException emailTaken() {
        return new ApiException(HttpStatus.CONFLICT, "EMAIL_ALREADY_REGISTERED",
                "Ya existe una cuenta con este correo.");
    }

    static String sha256(String value) {
        try {
            final byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
