/// Los 6 tipos de artículo del sistema (no se crean ni se editan). Son los
/// que deciden el comportamiento; las categorías son solo etiquetas.
/// Ver docs/MODELO_PRODUCTOS.md.
class TipoArticuloInfo {
  final String codigo;
  final String nombre;
  final String queEs;
  final String seVende;
  final String enRecetas;
  final String precio;

  const TipoArticuloInfo({
    required this.codigo,
    required this.nombre,
    required this.queEs,
    required this.seVende,
    required this.enRecetas,
    required this.precio,
  });

  static const todos = [
    TipoArticuloInfo(
      codigo: 'ELABORADO',
      nombre: 'Elaborado',
      queEs: 'Producto que se hace con una receta (ej.: Tarta de coco). Se crea desde Recetas.',
      seVende: 'Sí, salvo que sea una preparación base (ej.: ganache).',
      enRecetas: 'Solo si es una preparación base.',
      precio: 'Costo de la receta × (1 + % de ganancia).',
    ),
    TipoArticuloInfo(
      codigo: 'REVENTA',
      nombre: 'Reventa',
      queEs: 'Se compra y se vende tal cual (ej.: una gaseosa).',
      seVende: 'Sí.',
      enRecetas: 'No.',
      precio: 'Costo × (1 + % de ganancia); se puede fijar a mano sin bajar del %.',
    ),
    TipoArticuloInfo(
      codigo: 'MATERIA_PRIMA',
      nombre: 'Materia prima',
      queEs: 'Ingrediente que se usa solo en recetas (ej.: harina, coco).',
      seVende: 'No.',
      enRecetas: 'Sí.',
      precio: 'No tiene precio de venta: su costo forma parte del de las recetas.',
    ),
    TipoArticuloInfo(
      codigo: 'INSUMO',
      nombre: 'Insumo',
      queEs: 'Cajas, cintas, stickers.',
      seVende: 'No.',
      enRecetas: 'Sí, y también en el armado de paquetes.',
      precio: 'No tiene precio de venta: su costo forma parte del de recetas y paquetes.',
    ),
    TipoArticuloInfo(
      codigo: 'REVENTA_MATERIA_PRIMA',
      nombre: 'Reventa + materia prima',
      queEs: 'Se vende tal cual y también se usa en recetas (ej.: caja de bombones de 100 g).',
      seVende: 'Sí, por unidades enteras.',
      enRecetas: 'Sí.',
      precio: 'Como la reventa.',
    ),
    TipoArticuloInfo(
      codigo: 'PAQUETE',
      nombre: 'Paquete',
      queEs: 'Se arma con insumos (ej.: Paquete día de la madre). Los productos que van adentro se cobran aparte.',
      seVende: 'Sí, como una línea del ticket.',
      enRecetas: 'No.',
      precio: 'Costo del armado + un monto fijo.',
    ),
  ];
}
