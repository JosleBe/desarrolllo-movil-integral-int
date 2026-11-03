package mx.edu.utez.sruu.auth;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class InstitutionalEmailTest {

    @Test
    void aceptaCorreosUtezNormalizados() {
        assertThat(InstitutionalEmail.isValid("20223tn067@utez.edu.mx")).isTrue();
        assertThat(InstitutionalEmail.isValid("  Ana.Lopez@UTEZ.edu.mx ")).isTrue();
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "alguien@gmail.com", "a@utez.edu.mx.com", "a@fake.utez.edu.mx", "a@utez.edu",
        "@utez.edu.mx", "a@b@utez.edu.mx", "a..b@utez.edu.mx", ""})
    void rechazaOtrosDominios(String email) {
        assertThat(InstitutionalEmail.isValid(email)).isFalse();
    }

    @Test
    void politicaDeClave() {
        assertThat(PasswordPolicy.isAcceptable("Segura123")).isTrue();
        assertThat(PasswordPolicy.isAcceptable("corta1A")).isFalse();
        assertThat(PasswordPolicy.isAcceptable("sinnumeroA")).isFalse();
        assertThat(PasswordPolicy.isAcceptable("sinmayus1")).isFalse();
        assertThat(PasswordPolicy.isAcceptable("A1" + "a".repeat(71))).isFalse();
    }
}
