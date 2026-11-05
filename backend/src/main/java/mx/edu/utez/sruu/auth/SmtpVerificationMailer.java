package mx.edu.utez.sruu.auth;

import java.nio.charset.StandardCharsets;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;
import org.springframework.web.util.HtmlUtils;

import mx.edu.utez.sruu.config.SruuProperties;

/** Correo de verificación por SMTP (en desarrollo, Mailpit en http://localhost:8025). */
@Component
class SmtpVerificationMailer implements VerificationMailer {

    private final JavaMailSender sender;
    private final SruuProperties props;

    SmtpVerificationMailer(JavaMailSender sender, SruuProperties props) {
        this.sender = sender;
        this.props = props;
    }

    @Override
    public void send(String toEmail, String fullName, String code) {
        final String firstName = fullName.trim().split("\\s+")[0];
        final String text = """
                Hola, %s.

                Tu código para activar tu cuenta de SRUU es:

                    %s

                Escríbelo en la app. Vence en 24 horas y sirve una sola vez.
                Si no creaste una cuenta, ignora este correo.
                """.formatted(firstName, code);
        final String html = """
                <div style="font-family:Arial,sans-serif;font-size:16px;line-height:1.5;color:#03211A;max-width:520px">
                  <p style="font-size:26px;font-weight:700;margin:0 0 16px">Hola, %s.</p>
                  <p>Tu código para activar tu cuenta de SRUU es:</p>
                  <p style="display:inline-block;background:#009475;color:#ffffff;padding:14px 22px;font-size:30px;font-weight:700;letter-spacing:6px">%s</p>
                  <p style="color:#3c5a52">Escríbelo en la app. Vence en 24 horas y sirve una sola vez. Si no creaste una cuenta, ignora este correo.</p>
                </div>
                """.formatted(HtmlUtils.htmlEscape(firstName), HtmlUtils.htmlEscape(code));
        try {
            final MimeMessage message = sender.createMimeMessage();
            final MimeMessageHelper helper =
                    new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());
            helper.setFrom(props.mailFrom());
            helper.setTo(toEmail);
            helper.setSubject("Tu código de SRUU: " + code);
            helper.setText(text, html);
            sender.send(message);
        } catch (MessagingException e) {
            throw new IllegalStateException("No se pudo armar el correo de verificación", e);
        }
    }
}
