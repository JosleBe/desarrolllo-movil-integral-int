/// Permisos independientes de una cuenta (modelo ABAC del DFR, sección 5).
///
/// Los permisos de [renter] (Rentador) y [seller] (Vendedor) son
/// totalmente independientes y pueden estar activos de forma simultánea.
/// La combinación de ambos determina la capacidad operativa del usuario:
///
/// | Rentador | Vendedor | Perfil resultante           |
/// |----------|----------|-----------------------------|
/// | activo   | inactivo | Solo Consulta / Renta       |
/// | inactivo | activo   | Solo Publicación            |
/// | activo   | activo   | Perfil Estándar Completo    |
/// | inactivo | inactivo | Perfil Restringido (lectura)|
///
/// [reception] es un rol operativo aparte (personal del punto de control,
/// DFR sección 4): habilita el módulo de Recepción y no interviene en la
/// matriz Rentador/Vendedor.
class UserPermissions {
  const UserPermissions({
    this.renter = false,
    this.seller = false,
    this.reception = false,
    this.admin = false,
  });

  /// Permiso de Rentador activo: buscar y solicitar útiles.
  final bool renter;

  /// Permiso de Vendedor activo: publicar e inventariar útiles.
  final bool seller;

  /// Rol de personal de Recepción: escanear QR, recibir, entregar y
  /// registrar devoluciones (Épica 4).
  final bool reception;

  /// Rol de Administrador: resolver incidencias, suspender/reactivar
  /// permisos, auditoría y moderación del catálogo (Épica 5).
  final bool admin;

  /// Ningún permiso de renta/publicación activo: solo navegación e
  /// historial (perfil restringido). No considera los roles operativos.
  bool get isRestricted => !renter && !seller;

  /// Ambos permisos activos: acceso completo sin restricción modular.
  bool get isFull => renter && seller;

  UserPermissions copyWith({
    bool? renter,
    bool? seller,
    bool? reception,
    bool? admin,
  }) {
    return UserPermissions(
      renter: renter ?? this.renter,
      seller: seller ?? this.seller,
      reception: reception ?? this.reception,
      admin: admin ?? this.admin,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserPermissions &&
      other.renter == renter &&
      other.seller == seller &&
      other.reception == reception &&
      other.admin == admin;

  @override
  int get hashCode => Object.hash(renter, seller, reception, admin);

  @override
  String toString() =>
      'UserPermissions(renter: $renter, seller: $seller, '
      'reception: $reception, admin: $admin)';
}
