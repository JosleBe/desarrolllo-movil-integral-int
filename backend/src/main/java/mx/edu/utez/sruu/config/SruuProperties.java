package mx.edu.utez.sruu.config;

import java.time.Duration;
import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "sruu")
public record SruuProperties(
        Jwt jwt,
        Verification verification,
        String mailFrom,
        Cors cors,
        boolean seedDemo) {

    public record Jwt(String secret, Duration ttl) {}

    public record Verification(Duration ttl, Duration resendCooldown, int maxAttempts) {}

    public record Cors(List<String> allowedOriginPatterns) {}
}
