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
 * Solo desarrollo ({@code sruu.seed-demo=true}): crea la cuenta verificada
 * demo@utez.edu.mx / Demo1234, la misma que usa el modo demo de la app.
 */
@Component
@ConditionalOnProperty(name = "sruu.seed-demo", havingValue = "true")
class DemoDataSeeder implements ApplicationRunner {

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
        if (users.existsByEmailIgnoreCase("demo@utez.edu.mx")) {
            return;
        }
        final User demo = User.pending("demo@utez.edu.mx", "Ana Demo Ramírez", encoder.encode("Demo1234"), clock.instant());
        demo.markVerified(clock.instant());
        users.save(demo);
        log.info("Cuenta demo creada: demo@utez.edu.mx / Demo1234");
    }
}
