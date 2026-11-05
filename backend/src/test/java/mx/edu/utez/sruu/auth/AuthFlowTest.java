package mx.edu.utez.sruu.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Duration;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import mx.edu.utez.sruu.TestcontainersConfiguration;
import mx.edu.utez.sruu.support.CapturingMailer;
import mx.edu.utez.sruu.support.MutableClock;
import mx.edu.utez.sruu.support.TestBeans;

@SpringBootTest
@AutoConfigureMockMvc
@Import({TestcontainersConfiguration.class, TestBeans.class})
class AuthFlowTest {

    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired CapturingMailer mailer;
    @Autowired MutableClock clock;

    @BeforeEach
    void clean() {
        jdbc.execute("truncate users, verification_tokens, revoked_tokens cascade");
        mailer.sent.clear();
        clock.set(java.time.Instant.parse("2026-11-03T16:00:00Z"));
    }

    // ---------- helpers ----------

    ResultActions postJson(String path, String json) throws Exception {
        return mvc.perform(post(path).contentType(MediaType.APPLICATION_JSON).content(json));
    }

    ResultActions register(String email, String password) throws Exception {
        return postJson("/auth/register", """
                {"fullName":"Leo Martínez","email":"%s","password":"%s"}""".formatted(email, password));
    }

    ResultActions verify(String token) throws Exception {
        return postJson("/auth/verify", "{\"token\":\"%s\"}".formatted(token));
    }

    ResultActions login(String email, String password) throws Exception {
        return postJson("/auth/login", "{\"email\":\"%s\",\"password\":\"%s\"}".formatted(email, password));
    }

    String registerAndVerify(String email) throws Exception {
        register(email, "Segura123").andExpect(status().isCreated());
        verify(mailer.lastTo(email).token()).andExpect(status().isOk());
        return email;
    }

    String accessToken(String email) throws Exception {
        final String body = login(email, "Segura123").andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    // ---------- HU-01 ----------

    @Nested
    class HU01Registro {

        @Test
        void rechazaDominioDistintoConMensajeClaro() throws Exception {
            register("alguien@gmail.com", "Segura123")
                    .andExpect(status().isUnprocessableContent())
                    .andExpect(jsonPath("$.code").value("INSTITUTIONAL_EMAIL_REQUIRED"))
                    .andExpect(jsonPath("$.message").value("Solo se aceptan correos @utez.edu.mx."));
            assertThat(jdbc.queryForObject("select count(*) from users", Integer.class)).isZero();
        }

        @Test
        void creaLaCuentaPendienteDeVerificacion() throws Exception {
            register("20223TN067@utez.edu.mx", "Segura123")
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.user.email").value("20223tn067@utez.edu.mx"))
                    .andExpect(jsonPath("$.user.status").value("PENDIENTE_VERIFICACION"))
                    .andExpect(jsonPath("$.user.role").value("NINGUNO"))
                    .andExpect(jsonPath("$.user.passwordHash").doesNotExist());
        }

        @Test
        void guardaLaClaveConBcryptYNuncaEnClaro() throws Exception {
            register("leo@utez.edu.mx", "Segura123").andExpect(status().isCreated());
            final String hash = jdbc.queryForObject(
                    "select password_hash from users where email = 'leo@utez.edu.mx'", String.class);
            assertThat(hash).startsWith("$2a$12$").doesNotContain("Segura123");
        }

        @Test
        void elCorreoEsUnicoSinImportarMayusculas() throws Exception {
            register("leo@utez.edu.mx", "Segura123").andExpect(status().isCreated());
            register("LEO@utez.edu.mx", "Segura123")
                    .andExpect(status().isConflict())
                    .andExpect(jsonPath("$.code").value("EMAIL_ALREADY_REGISTERED"));
        }

        @Test
        void rechazaClavesDebiles() throws Exception {
            register("leo@utez.edu.mx", "debil")
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("WEAK_PASSWORD"));
        }
    }

    // ---------- HU-02 ----------

    @Nested
    class HU02Verificacion {

        @Test
        void alRegistrarseSeEnviaElTokenAlCorreo() throws Exception {
            register("leo@utez.edu.mx", "Segura123");
            final CapturingMailer.Sent mail = mailer.lastTo("leo@utez.edu.mx");
            assertThat(mail).isNotNull();
            assertThat(mail.link()).startsWith("http://localhost:8686/verificar?token=");
            assertThat(mail.token()).hasSizeGreaterThanOrEqualTo(43); // 256 bits en base64url
            // En la base solo queda el hash del token.
            assertThat(jdbc.queryForObject("select token_hash from verification_tokens", String.class))
                    .isNotEqualTo(mail.token()).hasSize(64);
        }

        @Test
        void tokenVigenteVerificaConRolUsuarioBase() throws Exception {
            register("leo@utez.edu.mx", "Segura123");
            verify(mailer.lastTo("leo@utez.edu.mx").token())
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.user.status").value("VERIFICADA"))
                    .andExpect(jsonPath("$.user.role").value("USUARIO_BASE"));
        }

        @Test
        void tokenYaUsadoOfreceReenviar() throws Exception {
            register("leo@utez.edu.mx", "Segura123");
            final String token = mailer.lastTo("leo@utez.edu.mx").token();
            verify(token).andExpect(status().isOk());
            verify(token)
                    .andExpect(status().isConflict())
                    .andExpect(jsonPath("$.code").value("TOKEN_ALREADY_USED"))
                    .andExpect(jsonPath("$.email").value("leo@utez.edu.mx"));
        }

        @Test
        void tokenVencidoOfreceReenviar() throws Exception {
            register("leo@utez.edu.mx", "Segura123");
            final String token = mailer.lastTo("leo@utez.edu.mx").token();
            clock.advance(Duration.ofHours(24));
            verify(token)
                    .andExpect(status().isGone())
                    .andExpect(jsonPath("$.code").value("TOKEN_EXPIRED"))
                    .andExpect(jsonPath("$.email").value("leo@utez.edu.mx"));
        }

        @Test
        void reenviarInvalidaElAnteriorYElNuevoFunciona() throws Exception {
            register("leo@utez.edu.mx", "Segura123");
            final String old = mailer.lastTo("leo@utez.edu.mx").token();
            clock.advance(Duration.ofSeconds(61));
            postJson("/auth/verify/resend", "{\"email\":\"leo@utez.edu.mx\"}").andExpect(status().isAccepted());
            final String fresh = mailer.lastTo("leo@utez.edu.mx").token();

            assertThat(fresh).isNotEqualTo(old);
            verify(old).andExpect(jsonPath("$.code").value("TOKEN_ALREADY_USED"));
            verify(fresh).andExpect(status().isOk());
        }

        @Test
        void reenviarRespetaElTiempoDeEspera() throws Exception {
            register("leo@utez.edu.mx", "Segura123");
            postJson("/auth/verify/resend", "{\"email\":\"leo@utez.edu.mx\"}")
                    .andExpect(status().isTooManyRequests())
                    .andExpect(jsonPath("$.code").value("RATE_LIMITED"));
        }

        @Test
        void reenviarAUnCorreoDesconocidoNoLoRevela() throws Exception {
            postJson("/auth/verify/resend", "{\"email\":\"nadie@utez.edu.mx\"}").andExpect(status().isAccepted());
            assertThat(mailer.sent).isEmpty();
        }

        @Test
        void tokenInexistenteEsInvalido() throws Exception {
            verify("no-existe").andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("TOKEN_INVALID"));
        }
    }

    // ---------- HU-03 ----------

    @Nested
    class HU03Sesion {

        @Test
        void credencialesCorrectasEmitenJwtConExpiracion() throws Exception {
            registerAndVerify("leo@utez.edu.mx");
            final String body = login("leo@utez.edu.mx", "Segura123")
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.user.role").value("USUARIO_BASE"))
                    .andReturn().getResponse().getContentAsString();
            final String token = JsonPath.read(body, "$.accessToken");
            final String expiresAt = JsonPath.read(body, "$.expiresAt");
            assertThat(token.split("\\.")).hasSize(3);
            assertThat(java.time.Instant.parse(expiresAt)).isEqualTo(clock.instant().plus(Duration.ofHours(8)));
        }

        @Test
        void errorGenericoSinRevelarQueDatoFallo() throws Exception {
            registerAndVerify("leo@utez.edu.mx");
            final String wrongPassword = login("leo@utez.edu.mx", "Otra1234")
                    .andExpect(status().isUnauthorized()).andReturn().getResponse().getContentAsString();
            final String unknownEmail = login("nadie@utez.edu.mx", "Segura123")
                    .andExpect(status().isUnauthorized()).andReturn().getResponse().getContentAsString();
            assertThat(wrongPassword).isEqualTo(unknownEmail).contains("INVALID_CREDENTIALS");
        }

        @Test
        void cuentaSinVerificarNoEntra() throws Exception {
            register("leo@utez.edu.mx", "Segura123");
            login("leo@utez.edu.mx", "Segura123")
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("EMAIL_NOT_VERIFIED"));
        }

        @Test
        void endpointsPrivadosExigenToken() throws Exception {
            mvc.perform(get("/auth/me")).andExpect(status().isUnauthorized());
            mvc.perform(get("/auth/me").header("Authorization", "Bearer basura")).andExpect(status().isUnauthorized());
        }

        @Test
        void alCerrarSesionElTokenQuedaInvalidado() throws Exception {
            final String token = accessToken(registerAndVerify("leo@utez.edu.mx"));
            mvc.perform(get("/auth/me").header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.email").value("leo@utez.edu.mx"));

            mvc.perform(post("/auth/logout").header("Authorization", "Bearer " + token))
                    .andExpect(status().isNoContent());

            mvc.perform(get("/auth/me").header("Authorization", "Bearer " + token))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        void unTokenVencidoDejaDeServir() throws Exception {
            final String token = accessToken(registerAndVerify("leo@utez.edu.mx"));
            clock.advance(Duration.ofHours(8).plusSeconds(1));
            mvc.perform(get("/auth/me").header("Authorization", "Bearer " + token))
                    .andExpect(status().isUnauthorized());
        }
    }
}
