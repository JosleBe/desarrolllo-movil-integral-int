package mx.edu.utez.sruu.auth;

/** Se publica dentro de la transacción; el correo sale solo si se confirma. */
record VerificationRequested(String email, String fullName, String token) {}
