enum Categoria {
  talavera('Talavera'),
  decoracion('Decoración'),
  dulces('Dulces típicos'),
  textiles('Textiles');

  final String etiqueta;
  const Categoria(this.etiqueta);
}

class Dimensiones {
  final double altoCm, anchoCm, largoCm;
  const Dimensiones(this.altoCm, this.anchoCm, this.largoCm);
  @override
  String toString() => '${altoCm.round()} × ${anchoCm.round()} × ${largoCm.round()} cm';
}

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final int precioCentavos;
  final Categoria categoria;
  final int existencias;
  final String emoji;
  final Dimensiones? dimensiones;
  final String? modeloGlb;
  final String? modeloUsdz;

  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioCentavos,
    required this.categoria,
    required this.existencias,
    required this.emoji,
    this.dimensiones,
    this.modeloGlb,
    this.modeloUsdz,
  });

  bool get disponible => existencias > 0;
  bool get tieneModelo3d => modeloGlb != null && modeloGlb!.startsWith('https://');

  Producto copiarCon({int? existencias, int? precioCentavos}) => Producto(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        precioCentavos: precioCentavos ?? this.precioCentavos,
        categoria: categoria,
        existencias: existencias ?? this.existencias,
        emoji: emoji,
        dimensiones: dimensiones,
        modeloGlb: modeloGlb,
        modeloUsdz: modeloUsdz,
      );
}
