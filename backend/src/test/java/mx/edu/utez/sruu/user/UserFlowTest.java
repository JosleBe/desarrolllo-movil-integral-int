package mx.edu.utez.sruu.user;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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

/** HU-04 (perfil), HU-05 (permisos en el servidor) y HU-24/25 (gestión por el admin). */
@SpringBootTest
@AutoConfigureMockMvc
@Import({TestcontainersConfiguration.class, TestBeans.class})
class UserFlowTest {

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

    ResultActions patchJson(String path, String token, String json) throws Exception {
        return mvc.perform(patch(path).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(json));
    }

    /** Registra, verifica, aplica permisos y devuelve el JWT. */
    String signedIn(String email, boolean renter, boolean seller, boolean admin) throws Exception {
        postJson("/auth/register", """
                {"fullName":"Cuenta %s","email":"%s","password":"password1"}"""
                .formatted(email, email)).andExpect(status().isCreated());
        postJson("/auth/verify", "{\"email\":\"%s\",\"code\":\"%s\"}"
                .formatted(email, mailer.lastTo(email).code())).andExpect(status().isOk());
        jdbc.update("update users set perm_renter = ?, perm_seller = ?, perm_admin = ? where email = ?",
                renter, seller, admin, email);
        final String body = postJson("/auth/login",
                "{\"email\":\"%s\",\"password\":\"password1\"}".formatted(email))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    String idOf(String email) {
        return jdbc.queryForObject("select id::text from users where email = ?", String.class, email);
    }

    // ---------- HU-04 ----------

    @Nested
    class HU04Perfil {

        @Test
        void editaNombreYTelefonoSinCambiarElCorreo() throws Exception {
            final String token = signedIn("leo@utez.edu.mx", true, false, false);
            patchJson("/users/me", token, "{\"fullName\":\" Leo Nuevo \",\"phone\":\"7779998888\"}")
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.fullName").value("Leo Nuevo"))
                    .andExpect(jsonPath("$.phone").value("7779998888"))
                    .andExpect(jsonPath("$.email").value("leo@utez.edu.mx"));
        }

        @Test
        void ignoraUnIntentoDeCambiarElCorreo() throws Exception {
            final String token = signedIn("leo@utez.edu.mx", true, false, false);
            patchJson("/users/me", token, "{\"email\":\"otro@utez.edu.mx\",\"fullName\":\"Leo\"}")
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.email").value("leo@utez.edu.mx"));
        }

        @Test
        void perfilRestringidoEsDeSoloLectura() throws Exception {
            final String token = signedIn("leo@utez.edu.mx", false, false, false);
            patchJson("/users/me", token, "{\"fullName\":\"Leo\"}")
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("PROFILE_READ_ONLY"));
            // Pero puede consultar su perfil.
            mvc.perform(get("/auth/me").header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.permissions.renter").value(false));
        }

        @Test
        void rechazaUnTelefonoConLetras() throws Exception {
            final String token = signedIn("leo@utez.edu.mx", true, true, false);
            patchJson("/users/me", token, "{\"phone\":\"llámame\"}")
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        }

        @Test
        void exigeSesion() throws Exception {
            mvc.perform(patch("/users/me").contentType(MediaType.APPLICATION_JSON).content("{}"))
                    .andExpect(status().isUnauthorized());
        }
    }

    // ---------- HU-05 / HU-24 / HU-25 ----------

    @Nested
    class PermisosPorCuenta {

        @Test
        void soloElAdministradorListaCuentas() throws Exception {
            final String user = signedIn("leo@utez.edu.mx", true, true, false);
            mvc.perform(get("/admin/users").header("Authorization", "Bearer " + user))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("FORBIDDEN"));

            final String admin = signedIn("admin@utez.edu.mx", false, false, true);
            mvc.perform(get("/admin/users").header("Authorization", "Bearer " + admin))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.length()").value(2))
                    .andExpect(jsonPath("$[0].passwordHash").doesNotExist());
        }

        @Test
        void suspenderUnPermisoNoAfectaAlOtro() throws Exception {
            signedIn("leo@utez.edu.mx", true, true, false);
            final String admin = signedIn("admin@utez.edu.mx", false, false, true);
            patchJson("/admin/users/" + idOf("leo@utez.edu.mx") + "/permissions", admin,
                    "{\"permission\":\"SELLER\",\"active\":false,\"reason\":\"Incumplimiento\"}")
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.permissions.seller").value(false))
                    .andExpect(jsonPath("$.permissions.renter").value(true));
        }

        @Test
        void reactivarDevuelveElPermiso() throws Exception {
            signedIn("leo@utez.edu.mx", true, false, false);
            final String admin = signedIn("admin@utez.edu.mx", false, false, true);
            patchJson("/admin/users/" + idOf("leo@utez.edu.mx") + "/permissions", admin,
                    "{\"permission\":\"SELLER\",\"active\":true}")
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.permissions.seller").value(true))
                    .andExpect(jsonPath("$.permissions.renter").value(true));
        }

        @Test
        void unUsuarioComunNoPuedeCambiarPermisos() throws Exception {
            final String user = signedIn("leo@utez.edu.mx", true, false, false);
            patchJson("/admin/users/" + idOf("leo@utez.edu.mx") + "/permissions", user,
                    "{\"permission\":\"SELLER\",\"active\":true}")
                    .andExpect(status().isForbidden());
        }

        @Test
        void cuentaInexistente() throws Exception {
            final String admin = signedIn("admin@utez.edu.mx", false, false, true);
            patchJson("/admin/users/00000000-0000-0000-0000-000000000000/permissions", admin,
                    "{\"permission\":\"RENTER\",\"active\":false}")
                    .andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.code").value("USER_NOT_FOUND"));
        }
    }
}
