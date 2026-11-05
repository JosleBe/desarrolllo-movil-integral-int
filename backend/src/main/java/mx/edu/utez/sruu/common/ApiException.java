package mx.edu.utez.sruu.common;

import java.util.Map;

import org.springframework.http.HttpStatus;

/**
 * Error de negocio con un código estable que la app interpreta
 * (ver app/docs/auth-api.md). {@code extra} viaja en el cuerpo de la respuesta.
 */
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String code;
    private final Map<String, Object> extra;

    public ApiException(HttpStatus status, String code, String message) {
        this(status, code, message, Map.of());
    }

    public ApiException(HttpStatus status, String code, String message, Map<String, Object> extra) {
        super(message);
        this.status = status;
        this.code = code;
        this.extra = extra;
    }

    public HttpStatus status() {
        return status;
    }

    public String code() {
        return code;
    }

    public Map<String, Object> extra() {
        return extra;
    }
}
