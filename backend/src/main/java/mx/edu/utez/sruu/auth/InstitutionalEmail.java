package mx.edu.utez.sruu.auth;

import java.util.Locale;
import java.util.regex.Pattern;

/** RN-01: solo correos del dominio exacto utez.edu.mx (sin subdominios). */
public final class InstitutionalEmail {

    public static final String DOMAIN = "utez.edu.mx";

    private static final Pattern PATTERN =
            Pattern.compile("^[a-z0-9](?:[a-z0-9._%+-]{0,62}[a-z0-9])?@utez\\.edu\\.mx$");

    private InstitutionalEmail() {}

    public static String normalize(String raw) {
        return raw == null ? "" : raw.trim().toLowerCase(Locale.ROOT);
    }

    public static boolean isValid(String raw) {
        final String email = normalize(raw);
        return PATTERN.matcher(email).matches() && !email.contains("..");
    }
}
