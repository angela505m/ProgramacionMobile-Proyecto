import 'package:flutter/material.dart';

class PoliticaPrivacidadView extends StatefulWidget {
  final Function(bool) onAccept;
  const PoliticaPrivacidadView({super.key, required this.onAccept});

  @override
  State<PoliticaPrivacidadView> createState() => _PoliticaPrivacidadViewState();
}

class _PoliticaPrivacidadViewState extends State<PoliticaPrivacidadView> {
  bool _aceptado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Política de Privacidad',
            style: TextStyle(color: Color(0xFF96C9F2))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF96C9F2)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child:
                  Icon(Icons.privacy_tip, size: 80, color: Color(0xFF96C9F2)),
            ),
            const SizedBox(height: 16),
            const Text(
              'PetCare respeta tu privacidad',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF96C9F2)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSection(Icons.pets, 'Datos de tus mascotas',
                'Nombre, tipo, edad y otros datos que agregues.'),
            _buildSection(Icons.location_on, 'Ubicación GPS',
                'Durante los paseos (solo con tu permiso).'),
            _buildSection(Icons.notifications, 'Recordatorios',
                'Horarios y tipos que configures.'),
            _buildSection(Icons.phone_android, 'Uso de notificaciones push',
                'Para recordatorios y alertas.'),
            const SizedBox(height: 24),
            const Text(
              'No compartimos tus datos con terceros. Puedes solicitar la eliminación de tus datos en cualquier momento desde Configuración.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Checkbox(
                  value: _aceptado,
                  onChanged: (value) =>
                      setState(() => _aceptado = value ?? false),
                  activeColor: const Color(0xFF96C9F2),
                ),
                const Expanded(
                  child: Text(
                    'He leído y acepto la Política de Privacidad y los Términos de Uso.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _aceptado
                  ? () {
                      widget.onAccept(true);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF96C9F2),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ACEPTAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: const Color(0xFF96C9F2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
