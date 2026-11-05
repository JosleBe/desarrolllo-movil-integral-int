package mx.edu.utez.sruu.auth;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.web.util.UriComponentsBuilder;

import mx.edu.utez.sruu.config.SruuProperties;

@Component
class VerificationMailListener {

    private static final Logger log = LoggerFactory.getLogger(VerificationMailListener.class);

    private final VerificationMailer mailer;
    private final SruuProperties props;

    VerificationMailListener(VerificationMailer mailer, SruuProperties props) {
        this.mailer = mailer;
        this.props = props;
    }

    @TransactionalEventListener
    void on(VerificationRequested event) {
        final String link = UriComponentsBuilder.fromUriString(props.webBaseUrl())
                .path("/verificar")
                .queryParam("token", event.token())
                .toUriString();
        try {
            mailer.send(event.email(), event.fullName(), link);
        } catch (RuntimeException e) {
            // La cuenta ya existe; el usuario puede pedir un reenvío.
            log.error("No se pudo enviar el correo de verificación a {}", event.email(), e);
        }
    }
}
