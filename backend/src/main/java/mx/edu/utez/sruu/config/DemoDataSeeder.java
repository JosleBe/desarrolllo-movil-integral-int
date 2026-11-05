package mx.edu.utez.sruu.config;

import java.time.Clock;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import mx.edu.utez.sruu.user.User;
import mx.edu.utez.sruu.user.UserRepository;

/**
 * Solo desarrollo ({@code sruu.seed-demo=true}): deja listas, verificadas,
 * las mismas cuentas que trae el mock de la app ({@code MockAuthRepository}),
 * con sus claves y permisos. Si ya existen, restablece clave y permisos.
 */
@Component
@ConditionalOnProperty(name = "sruu.seed-demo", havingValue = "true")
class DemoDataSeeder implements ApplicationRunner {

    private record Demo(String email, String fullName, String password, String phone,
                        boolean renter, boolean seller, boolean reception, boolean admin) {}

    private static final Demo[] ACCOUNTS = {
        new Demo("demo@utez.edu.mx", "Usuario Demo", "demo1234", "7771234567", true, true, true, true),
        new Demo("laura@utez.edu.mx", "Laura M.", "laura1234", null, true, true, false, false),
        new Demo("pedro@utez.edu.mx", "Pedro S.", "pedro1234", null, false, true, false, false),
    };

    private static final Logger log = LoggerFactory.getLogger(DemoDataSeeder.class);

    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final Clock clock;

    DemoDataSeeder(UserRepository users, PasswordEncoder encoder, Clock clock) {
        this.users = users;
        this.encoder = encoder;
        this.clock = clock;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        for (final Demo demo : ACCOUNTS) {
            final User user = users.findByEmailIgnoreCase(demo.email()).orElseGet(() ->
                    User.pending(demo.email(), demo.fullName(), encoder.encode(demo.password()), clock.instant()));
            if (!encoder.matches(demo.password(), user.getPasswordHash())) {
                user.replacePasswordHash(encoder.encode(demo.password()));
            }
            if (!user.isVerified()) {
                user.markVerified(clock.instant());
            }
            user.updateContact(null, demo.phone());
            user.setPermissions(demo.renter(), demo.seller(), demo.reception(), demo.admin());
            users.save(user);
            log.info("Cuenta demo lista: {} / {}", demo.email(), demo.password());
        }
    }
}
