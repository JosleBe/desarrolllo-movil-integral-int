package mx.edu.utez.sruu.auth;

/**
 * Misma regla que la app del equipo: de 8 a 72 caracteres
 * (72 es el máximo que BCrypt toma en cuenta).
 */
public final class PasswordPolicy {

    public static final int MIN_LENGTH = 8;
    public static final int MAX_LENGTH = 72;

    private PasswordPolicy() {}

    public static boolean isAcceptable(String password) {
        return password != null && password.length() >= MIN_LENGTH && password.length() <= MAX_LENGTH;
    }
}
