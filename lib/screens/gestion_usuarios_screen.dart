import 'package:flutter/material.dart';
import 'package:app_inventario/services/database_helper.dart';
import 'package:go_router/go_router.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  late Future<List<User>> _futureUsuarios;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  void _cargarUsuarios() {
    setState(() {
      _futureUsuarios = DbHelper.instance.getUsuarios();
    });
  }

  void _mostrarModalCrearUsuario() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Operador');
    final formKey = GlobalKey<FormState>();

    List<String> rolesPredefinidos = ['Administrador', 'Operador', 'Cajero', 'Vendedor'];
    String rolSeleccionado = 'Operador';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CREAR NUEVO USUARIO Y ROL',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: userCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.person_add, color: Color(0xFF5AE6DF)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF5AE6DF)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                const Text('Asignar Rol:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: rolSeleccionado,
                  dropdownColor: const Color(0xFF121212),
                  style: const TextStyle(color: Colors.white),
                  items: rolesPredefinidos
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => rolSeleccionado = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final nuevo = User(
                          username: userCtrl.text.trim(),
                          password: passCtrl.text.trim(),
                          role: rolSeleccionado,
                        );
                        await DbHelper.instance.crearUsuario(nuevo);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _cargarUsuarios();
                      }
                    },
                    child: const Text('GUARDAR USUARIO', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('GESTIÓN DE USUARIOS Y ROLES',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5AE6DF),
        onPressed: _mostrarModalCrearUsuario,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: FutureBuilder<List<User>>(
        future: _futureUsuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5AE6DF)));
          }
          final usuarios = snapshot.data ?? [];
          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, i) {
              final u = usuarios[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF5AE6DF).withValues(alpha: 0.2),
                  child: Text(u.username[0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFF5AE6DF))),
                ),
                title: Text(u.username, style: const TextStyle(color: Colors.white)),
                subtitle: Text('Rol: ${u.role}', style: const TextStyle(color: Colors.grey)),
                trailing: u.username == 'admin'
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    await DbHelper.instance.eliminarUsuario(u.id!);
                    _cargarUsuarios();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}