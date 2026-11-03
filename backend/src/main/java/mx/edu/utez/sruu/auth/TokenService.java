package mx.edu.utez.sruu.auth;

import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

import mx.edu.utez.sruu.config.SruuProperties;
import mx.edu.utez.sruu.user.User;

@Service
class TokenService {

    record IssuedToken(String value, Instant expiresAt) {}

    private final JwtEncoder encoder;
    private final SruuProperties props;
    private final Clock clock;

    TokenService(JwtEncoder encoder, SruuProperties props, Clock clock) {
        this.encoder = encoder;
        this.props = props;
        this.clock = clock;
    }

    IssuedToken issue(User user) {
        final Instant now = clock.instant().truncatedTo(ChronoUnit.SECONDS);
        final Instant expiresAt = now.plus(props.jwt().ttl());
        final JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("sruu")
                .subject(user.getId().toString())
                .id(UUID.randomUUID().toString())
                .issuedAt(now)
                .expiresAt(expiresAt)
                .claim("email", user.getEmail())
                .claim("role", user.getRole().name())
                .build();
        final JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        final String value = encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
        return new IssuedToken(value, expiresAt);
    }
}
