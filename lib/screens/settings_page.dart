import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nombreLocalCtrl = TextEditingController();
  bool _alertasActivas = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
    _cargarCategorias(); // Carga los datos al abrir la ventana
  }

  // FUNCIÓN PARA CARGAR DATOS
  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreLocalCtrl.text = prefs.getString('nombre_negocio') ?? "PANADERIA";
      _alertasActivas = prefs.getBool('alertas_stock') ?? true;
    });
  }

  void _notificar(String msg, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: esError ? Colors.redAccent : const Color(0xFF5AE6DF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

 // FUNCIÓN PARA GUARDAR DATOS Y REGRESAR
  Future<void> _guardarConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardamos los valores
      await prefs.setString('nombre_negocio', _nombreLocalCtrl.text.trim());
      await prefs.setBool('alertas_stock', _alertasActivas);
      await prefs.setStringList('lista_categorias', _categorias);

      // Notificamos al usuario
      _notificar("Configuración guardada correctamente");

      // REGRESAR A LA PANTALLA ANTERIOR (Main)
      // Usamos un pequeño delay para que el usuario alcance a ver el SnackBar
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      _notificar("Error al guardar: $e", esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CONFIGURACIÓN"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF5AE6DF)),
            onPressed: _guardarConfiguracion, // Guarda los cambios
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader("DATOS DEL NEGOCIO"),
          const SizedBox(height: 10),
          TextField(
            controller: _nombreLocalCtrl,
            decoration: const InputDecoration(
              labelText: "Nombre del Establecimiento",
              prefixIcon: Icon(Icons.storefront),
            ),
          ),

          const Divider(height: 20, color: Colors.white10),

          _buildHeader("PREFERENCIAS"),
          SwitchListTile(
            title: const Text("Notificar Stock Bajo"),
            subtitle: const Text("Resaltar productos con menos de 5 unidades"),
            value: _alertasActivas, // Esta variable debe estar definida arriba
            activeColor: const Color(0xFF5AE6DF),
            onChanged: (val) {
              // Llamamos a la función de guardado rápido que creamos
              _guardarSoloCheck(val);
            },
          ),
          const Divider(height: 40, color: Colors.white10),
          _buildHeader("GESTIÓN DE CATEGORÍAS"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nuevaCatCtrl,
                  decoration: const InputDecoration(
                    hintText: "Ej: Integral, Especial...",
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _agregarCategoria, // <--- Llamar a la función aquí
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5AE6DF)),
                child: const Icon(Icons.add, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Mostrar las categorías actuales para confirmar que se agregan
          Wrap(
            spacing: 8,
            children: _categorias
                .map((cat) => Chip(
                      label: Text(cat),
                      onDeleted: () async {
                        setState(() => _categorias.remove(cat));
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setStringList(
                            'lista_categorias', _categorias);
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          _buildHeader("EQUIPO DE DESARROLLO"),
          const SizedBox(height: 10),
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text("José"),
            subtitle: Text("Arquitecto / Líder Técnico"),
          ),
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text("Bolívar"),
            subtitle: Text("UI / Frontend"),
          ),
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text("Valeria"),
            subtitle: Text("Analista / QA"),
          ),
        ],
      ),
    );
  }

// Crea esta función rápida dentro de _SettingsPageState
  Future<void> _guardarSoloCheck(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alertas_stock', valor);
    setState(() => _alertasActivas = valor);
  }

  Widget _buildHeader(String text) {
    return Text(text,
        style: const TextStyle(
            color: Color(0xFF5AE6DF),
            fontWeight: FontWeight.bold,
            fontSize: 12));
  }

  // Dentro de _SettingsPageState
  // 1. Declarar las variables dentro de _SettingsPageState
  final _nuevaCatCtrl = TextEditingController();
  List<String> _categorias = [
    'Salado',
    'Dulce',
    'Pastelería',
    'Bebida',
    'Otro'
  ];

// 2. Cargar desde SharedPreferences
  Future<void> _cargarCategorias() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? guardadas = prefs.getStringList('lista_categorias');
    if (guardadas != null) {
      setState(() {
        _categorias = guardadas;
      });
    }
  }

// 3. Función corregida para agregar
  void _agregarCategoria() async {
    String nombre = _nuevaCatCtrl.text.trim();

    if (nombre.isNotEmpty) {
      if (_categorias.contains(nombre)) {
        _notificar("La categoría ya existe", esError: true);
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // 1. Quitamos "Otro" temporalmente para ordenar el resto
        _categorias.remove("Otro");

        // 2. Agregamos la nueva
        _categorias.add(nombre);

        // 3. Ordenamos alfabéticamente las categorías normales
        _categorias.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        // 4. Insertamos "Otro" siempre al final
        _categorias.add("Otro");

        _nuevaCatCtrl.clear();
      });

      // Guardar la lista ya ordenada
      await prefs.setStringList('lista_categorias', _categorias);
      _notificar("Categoría '$nombre' añadida");
    }
  }
}
