package mx.edu.utez.sruu.auth;

import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

import mx.edu.utez.sruu.config.SruuProperties;

/** JWT HS256 firmados con la clave de {@code sruu.jwt.secret}. */
@Configuration(proxyBeanMethods = false)
class JwtConfig {

    @Bean
    SecretKey jwtKey(SruuProperties props) {
        final byte[] bytes = props.jwt().secret().getBytes(StandardCharsets.UTF_8);
        if (bytes.length < 32) {
            throw new IllegalStateException("sruu.jwt.secret debe tener al menos 32 bytes");
        }
        return new SecretKeySpec(bytes, "HmacSHA256");
    }

    @Bean
    JwtEncoder jwtEncoder(SecretKey key) {
        return new NimbusJwtEncoder(new ImmutableSecret<>(key));
    }

    /**
     * Valida firma, expiración (sin tolerancia extra) y que el {@code jti} no
     * esté en la lista de revocación (HU-03: al cerrar sesión el token deja de servir).
     */
    @Bean
    JwtDecoder jwtDecoder(SecretKey key, Clock clock, RevokedTokenRepository revoked) {
        final NimbusJwtDecoder decoder =
                NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS256).build();

        final JwtTimestampValidator timestamps = new JwtTimestampValidator(Duration.ZERO);
        timestamps.setClock(clock);

        final OAuth2TokenValidator<Jwt> notRevoked = jwt -> {
            final String jti = jwt.getId();
            if (jti == null || revoked.existsById(jti)) {
                return OAuth2TokenValidatorResult.failure(
                        new OAuth2Error("invalid_token", "El token fue revocado", null));
            }
            return OAuth2TokenValidatorResult.success();
        };

        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(timestamps, notRevoked));
        return decoder;
    }
}
