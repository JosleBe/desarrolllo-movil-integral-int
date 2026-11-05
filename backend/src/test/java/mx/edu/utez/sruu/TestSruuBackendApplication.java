package mx.edu.utez.sruu;

import org.springframework.boot.SpringApplication;

public class TestSruuBackendApplication {

	public static void main(String[] args) {
		SpringApplication.from(SruuBackendApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
