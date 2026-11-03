package mx.edu.utez.sruu;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@Import(TestcontainersConfiguration.class)
@SpringBootTest
class SruuBackendApplicationTests {

	@Test
	void contextLoads() {
	}

}
