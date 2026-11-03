package mx.edu.utez.sruu.auth;

/** Mismas reglas que muestra la app: 8–72 caracteres, mayúscula, minúscula y número. */
public final class PasswordPolicy {

    private PasswordPolicy() {}

    public static boolean isAcceptable(String password) {
        if (password == null || password.length() < 8 || password.length() > 72) {
            return false;
        }
        return password.chars().anyMatch(Character::isUpperCase)
                && password.chars().anyMatch(Character::isLowerCase)
                && password.chars().anyMatch(Character::isDigit);
    }
}
