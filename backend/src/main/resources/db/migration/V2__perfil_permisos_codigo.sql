-- Alinea el backend con el contrato de la app del equipo (Épica 1).

-- HU-04: dato de contacto editable.
alter table users add column phone varchar(20);

-- HU-05 / DFR sección 5: permisos independientes por cuenta (ABAC).
-- renter y seller son independientes (RN-02); reception y admin son roles operativos.
alter table users add column perm_renter    boolean not null default false;
alter table users add column perm_seller    boolean not null default false;
alter table users add column perm_reception boolean not null default false;
alter table users add column perm_admin     boolean not null default false;

-- HU-02: la verificación pasa a ser un código de 6 dígitos ligado a la cuenta.
-- El hash ya no es único global (dos cuentas pueden recibir el mismo código)
-- y se cuentan los intentos fallidos para frenar la fuerza bruta.
alter table verification_tokens drop constraint verification_tokens_token_hash_key;
alter table verification_tokens add column failed_attempts integer not null default 0;
