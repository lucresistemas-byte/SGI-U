/// Familias de unidades: solo se convierte dentro de una familia. El stock y
/// el costo de las materias primas se guardan en la unidad base.
enum FamiliaUnidad {
  peso('PESO', 'Peso'),
  volumen('VOLUMEN', 'Volumen'),
  longitud('LONGITUD', 'Longitud'),
  unidad('UNIDAD', 'Unidades');

  final String codigo;
  final String nombre;
  const FamiliaUnidad(this.codigo, this.nombre);

  static FamiliaUnidad? deCodigo(String? codigo) {
    for (final f in values) {
      if (f.codigo == codigo) return f;
    }
    return null;
  }

  /// Unidades de la familia, de la más chica (la base) a la más grande.
  List<UnidadMedida> get unidades => UnidadMedida.values.where((u) => u.familia == this).toList();

  UnidadMedida get base => unidades.first;
}

/// Unidades de medida. KILO = 1000 g, LITRO = 1000 ml, METRO = 100 cm,
/// DOCENA = 12 unidades. CAJA es solo de productos (sin familia).
enum UnidadMedida {
  gramo('GRAMO', FamiliaUnidad.peso, 1, 'g', 'Gramo'),
  kilo('KILO', FamiliaUnidad.peso, 1000, 'kg', 'Kilo'),
  mililitro('MILILITRO', FamiliaUnidad.volumen, 1, 'ml', 'Mililitro'),
  litro('LITRO', FamiliaUnidad.volumen, 1000, 'l', 'Litro'),
  centimetro('CENTIMETRO', FamiliaUnidad.longitud, 1, 'cm', 'Centímetro'),
  metro('METRO', FamiliaUnidad.longitud, 100, 'm', 'Metro'),
  unidad('UNIDAD', FamiliaUnidad.unidad, 1, 'u', 'Unidad'),
  docena('DOCENA', FamiliaUnidad.unidad, 12, 'docena', 'Docena'),
  caja('CAJA', null, 1, 'caja', 'Caja');

  final String codigo;
  final FamiliaUnidad? familia;
  final double factor;
  final String abreviatura;
  final String nombre;
  const UnidadMedida(this.codigo, this.familia, this.factor, this.abreviatura, this.nombre);

  static UnidadMedida? deCodigo(String? codigo) {
    for (final u in values) {
      if (u.codigo == codigo) return u;
    }
    return null;
  }

  /// Unidades que se pueden usar en materias primas (todas menos CAJA).
  static List<UnidadMedida> get conFamilia => values.where((u) => u.familia != null).toList();

  /// 2,5 kg → 2500 g.
  double aBase(double cantidad) => cantidad * factor;

  /// 2500 g → 2,5 kg.
  double desdeBase(double cantidadBase) => cantidadBase / factor;
}
