-- Épica 1: usuarios, tokens de verificación de correo y lista de revocación de JWT.

create table users (
    id            uuid         primary key,
    email         varchar(254) not null,
    full_name     varchar(120) not null,
    password_hash varchar(100) not null,
    status        varchar(30)  not null,
    role          varchar(30)  not null,
    created_at    timestamptz  not null,
    verified_at   timestamptz
);

-- Correo único sin distinguir mayúsculas.
create unique index ux_users_email on users (lower(email));

create table verification_tokens (
    id         uuid        primary key,
    user_id    uuid        not null references users (id) on delete cascade,
    -- Solo se guarda el SHA-256 del token; el token en claro viaja únicamente en el correo.
    token_hash varchar(64) not null unique,
    expires_at timestamptz not null,
    used_at    timestamptz,
    revoked_at timestamptz,
    created_at timestamptz not null
);

create index ix_verification_tokens_user on verification_tokens (user_id);

-- JWT invalidados al cerrar sesión (por jti) hasta que expiran.
create table revoked_tokens (
    jti        varchar(64) primary key,
    expires_at timestamptz not null
);
