package mx.edu.utez.sruu.auth;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
class VerificationMailListener {

    private static final Logger log = LoggerFactory.getLogger(VerificationMailListener.class);

    private final VerificationMailer mailer;

    VerificationMailListener(VerificationMailer mailer) {
        this.mailer = mailer;
    }

    @TransactionalEventListener
    void on(VerificationRequested event) {
        try {
            mailer.send(event.email(), event.fullName(), event.code());
        } catch (RuntimeException e) {
            // La cuenta ya existe; el usuario puede pedir un reenvío.
            log.error("No se pudo enviar el correo de verificación a {}", event.email(), e);
        }
    }
}
