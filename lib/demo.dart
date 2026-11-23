import 'format.dart';
import 'models.dart';

/// Datos simulados para que la app no se vea vacía mientras no hay
/// actividad real. Se muestran siempre marcados como "Ejemplo" y nunca se
/// guardan en Firestore ni en el backend.

const _demoPrefix = 'demo-';

bool esDemo(String id) => id.startsWith(_demoPrefix);

DateTime _en(int dias) => hoyDia().add(Duration(days: dias));

Encargo _e(
  String id, {
  required String sender,
  required String origen,
  required String destino,
  required int diasLimite,
  required String descripcion,
  required String categoria,
  required Tamano tamano,
  required double peso,
  required double precio,
  String moneda = 'USD',
  String estado = 'publicado',
}) =>
    Encargo(
      id: '$_demoPrefix$id',
      senderId: '${_demoPrefix}user-$id',
      senderName: sender,
      ciudadOrigen: origen,
      ciudadDestino: destino,
      fechaLimite: _en(diasLimite),
      descripcion: descripcion,
      categoria: categoria,
      tamano: tamano,
      pesoKg: peso,
      precio: precio,
      moneda: moneda,
      estado: estado,
      createdAt: DateTime.now().subtract(Duration(hours: diasLimite * 3 + 2)),
    );

/// Encargos publicados por otras personas (lo que ve un viajero).
/// Si se pasa una ruta, los ejemplos usan esa ruta para que coincidan con el vuelo.
List<Encargo> demoMercado({String? origen, String? destino}) {
  final base = <Encargo>[
    _e('m1',
        sender: 'Laura Gómez',
        origen: 'Bogota',
        destino: 'Madrid',
        diasLimite: 12,
        descripcion: 'Documentos de visa en sobre sellado para mi hermana. Muy livianos, sin líquidos.',
        categoria: 'documentos',
        tamano: Tamano.pequeno,
        peso: 0.4,
        precio: 45),
    _e('m2',
        sender: 'Andrés Pardo',
        origen: 'Medellin',
        destino: 'Miami',
        diasLimite: 9,
        descripcion: 'Café de origen de Jardín, Antioquia: 2 bolsas de 500 g selladas al vacío con factura.',
        categoria: 'regalos',
        tamano: Tamano.mediano,
        peso: 1.2,
        precio: 60),
    _e('m3',
        sender: 'Valentina Ruiz',
        origen: 'Bogota',
        destino: 'Paris',
        diasLimite: 18,
        descripcion: 'Libros de diseño para mi tesis (3 tomos). Van en caja de cartón con protección.',
        categoria: 'libros',
        tamano: Tamano.mediano,
        peso: 3.5,
        precio: 80),
    _e('m4',
        sender: 'Camilo Herrera',
        origen: 'Cali',
        destino: 'Madrid',
        diasLimite: 15,
        descripcion: 'Audífonos nuevos en su caja original, con factura de compra. Regalo de cumpleaños.',
        categoria: 'electronicos',
        tamano: Tamano.pequeno,
        peso: 0.6,
        precio: 55),
    _e('m5',
        sender: 'Mariana Ortiz',
        origen: 'Cartagena',
        destino: 'Miami',
        diasLimite: 7,
        descripcion: 'Vestido de baño artesanal y dos sombreros vueltiaos para una boutique.',
        categoria: 'ropa',
        tamano: Tamano.mediano,
        peso: 2,
        precio: 70),
    _e('m6',
        sender: 'Sofía Castaño',
        origen: 'Bogota',
        destino: 'Miami',
        diasLimite: 10,
        descripcion: 'Kit de cuidado facial (cremas en tubos cerrados, menos de 100 ml cada una).',
        categoria: 'cosmeticos',
        tamano: Tamano.pequeno,
        peso: 0.8,
        precio: 35),
  ];
  if (origen == null || destino == null) return base;
  // Mismos ejemplos, pero en la ruta del vuelo del viajero.
  return [
    for (final e in base.take(4))
      Encargo(
        id: e.id,
        senderId: e.senderId,
        senderName: e.senderName,
        ciudadOrigen: origen,
        ciudadDestino: destino,
        fechaLimite: e.fechaLimite,
        descripcion: e.descripcion,
        categoria: e.categoria,
        tamano: e.tamano,
        pesoKg: e.pesoKg,
        precio: e.precio,
        moneda: e.moneda,
        createdAt: e.createdAt,
      ),
  ];
}

/// Envíos propios de ejemplo (lo que ve un remitente sin envíos).
List<Encargo> demoMisEnvios() => [
      _e('s1',
          sender: 'Tú',
          origen: 'Bogota',
          destino: 'Madrid',
          diasLimite: 14,
          descripcion: 'Regalo de cumpleaños para mi mamá: bufanda tejida y una tarjeta.',
          categoria: 'regalos',
          tamano: Tamano.pequeno,
          peso: 0.5,
          precio: 40),
      _e('s2',
          sender: 'Tú',
          origen: 'Medellin',
          destino: 'Miami',
          diasLimite: 6,
          descripcion: 'Tablet usada para mi sobrino, en su caja con cargador.',
          categoria: 'electronicos',
          tamano: Tamano.mediano,
          peso: 1.1,
          precio: 65,
          estado: 'asignado'),
      _e('s3',
          sender: 'Tú',
          origen: 'Cali',
          destino: 'Paris',
          diasLimite: -5,
          descripcion: 'Documentos de matrícula universitaria apostillados.',
          categoria: 'documentos',
          tamano: Tamano.pequeno,
          peso: 0.3,
          precio: 50,
          estado: 'entregado'),
    ];

/// Interesados simulados por encargo de ejemplo (para el contador).
int demoInteresados(String id) => switch (id) {
      'demo-s1' => 3,
      'demo-m1' => 2,
      'demo-m3' => 1,
      _ => 0,
    };

class DemoMensaje {
  final bool mio;
  final String texto;
  final String hora;
  const DemoMensaje(this.mio, this.texto, this.hora);
}

class DemoChat {
  final String id;
  final String nombre;
  final String rol; // 'Viajero' o 'Remitente'
  final String vuelo;
  final String origen;
  final String destino;
  final String descripcion;
  final double precio;
  final bool noLeido;
  final List<DemoMensaje> mensajes;
  const DemoChat({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.vuelo,
    required this.origen,
    required this.destino,
    required this.descripcion,
    required this.precio,
    required this.noLeido,
    required this.mensajes,
  });
}

const demoChats = <DemoChat>[
  DemoChat(
    id: 'demo-c1',
    nombre: 'Julián Moreno',
    rol: 'Viajero',
    vuelo: 'AV 026',
    origen: 'Bogota',
    destino: 'Madrid',
    descripcion: 'Regalo de cumpleaños: bufanda y tarjeta',
    precio: 40,
    noLeido: true,
    mensajes: [
      DemoMensaje(false, '¡Hola! Vi tu encargo. Vuelo el jueves en la noche desde El Dorado.', '09:12'),
      DemoMensaje(true, 'Hola Julián, ¡qué bien! ¿Te queda bien recibirlo el miércoles?', '09:20'),
      DemoMensaje(false, 'Sí, perfecto. Puedo pasar por Chapinero después de las 6 p. m.', '09:22'),
      DemoMensaje(true, 'Listo. Te lo entrego abierto para que revises qué llevas.', '09:25'),
      DemoMensaje(false, 'Gracias 🙌 En Madrid se lo entrego a tu mamá el viernes en la tarde.', '09:31'),
    ],
  ),
  DemoChat(
    id: 'demo-c2',
    nombre: 'Natalia Ríos',
    rol: 'Remitente',
    vuelo: 'LA 4211',
    origen: 'Medellin',
    destino: 'Miami',
    descripcion: 'Tablet con cargador',
    precio: 65,
    noLeido: false,
    mensajes: [
      DemoMensaje(false, 'Hola, gracias por aceptar llevar la tablet. ¿Dónde nos vemos?', 'Ayer'),
      DemoMensaje(true, 'Hola Natalia, puedo en el centro comercial El Tesoro el sábado.', 'Ayer'),
      DemoMensaje(false, 'Perfecto, a las 11 a. m. Te llevo la factura también.', 'Ayer'),
    ],
  ),
];
