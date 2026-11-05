package mx.edu.utez.sruu.auth;

/** Envía el código de verificación de la cuenta (HU-02). */
public interface VerificationMailer {

    void send(String toEmail, String fullName, String code);
}
