package mx.edu.utez.sruu.support;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import mx.edu.utez.sruu.auth.VerificationMailer;

/** Sustituye al SMTP en pruebas y guarda los correos "enviados". */
public class CapturingMailer implements VerificationMailer {

    public record Sent(String to, String fullName, String code) {}

    public final List<Sent> sent = new CopyOnWriteArrayList<>();

    @Override
    public void send(String toEmail, String fullName, String code) {
        sent.add(new Sent(toEmail, fullName, code));
    }

    public Sent lastTo(String email) {
        for (int i = sent.size() - 1; i >= 0; i--) {
            if (sent.get(i).to().equals(email)) {
                return sent.get(i);
            }
        }
        return null;
    }
}
