package mx.edu.utez.sruu.auth;

/** Envía el enlace de verificación (HU-02). */
public interface VerificationMailer {

    void send(String toEmail, String fullName, String verificationLink);
}
