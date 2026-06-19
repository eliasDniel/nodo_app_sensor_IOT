import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../config/centinela_config.dart';
import '../../providers/centinela_provider.dart';
import '../../services/location_service.dart';
import 'home_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isConnecting = false;
  bool _isFetchingLocation = false;
  String? _locationMessage;
  LocationFailure? _locationFailure;
  int _durationSeconds = CentinelaConfig.eventDurationSeconds;
  double _thresholdDb = CentinelaConfig.thresholdDb;

  @override
  void initState() {
    super.initState();

    // Pre-cargar con los valores actuales de CentinelaConfig (incluyendo los guardados)
    _nameCtrl = TextEditingController(text: CentinelaConfig.connectionName);
    _codigoCtrl = TextEditingController(text: CentinelaConfig.codigoNodo);
    _latCtrl = TextEditingController(text: CentinelaConfig.latitud.toString());
    _lngCtrl = TextEditingController(text: CentinelaConfig.longitud.toString());
    _hostCtrl = TextEditingController(text: CentinelaConfig.brokerHost);
    _portCtrl = TextEditingController(text: CentinelaConfig.brokerPort.toString());
    _durationSeconds = CentinelaConfig.eventDurationSeconds;
    _thresholdDb = CentinelaConfig.thresholdDb;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward().then((_) {
      if (mounted) _initFromConfigAndLocation();
    });
  }

  Future<void> _initFromConfigAndLocation() async {
    // Esperar a que la Activity esté visible antes de pedir permisos (Android).
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final provider = context.read<CentinelaProvider>();
    while (!provider.configLoaded) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    _nameCtrl.text = CentinelaConfig.connectionName;
    _codigoCtrl.text = CentinelaConfig.codigoNodo;
    _hostCtrl.text = CentinelaConfig.brokerHost;
    _portCtrl.text = CentinelaConfig.brokerPort.toString();
    setState(() {
      _durationSeconds = CentinelaConfig.eventDurationSeconds;
      _thresholdDb = CentinelaConfig.thresholdDb;
    });

    await _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() {
      _isFetchingLocation = true;
      _locationMessage = null;
      _locationFailure = null;
    });

    final result = await LocationService.fetchCurrentPosition();

    if (!mounted) return;
    setState(() {
      _isFetchingLocation = false;
      if (result.isSuccess) {
        _latCtrl.text = result.location!.latitude.toStringAsFixed(6);
        _lngCtrl.text = result.location!.longitude.toStringAsFixed(6);
        _locationMessage = 'Ubicación obtenida correctamente';
      } else {
        _locationFailure = result.failure;
        _locationMessage = _messageForFailure(result.failure);
      }
    });
  }

  String _messageForFailure(LocationFailure? failure) => switch (failure) {
        LocationFailure.permissionDenied =>
          'Permiso de ubicación denegado. Toca el botón para volver a solicitarlo.',
        LocationFailure.permissionDeniedForever =>
          'Permiso bloqueado. Ábrelo en Ajustes → Permisos → Ubicación.',
        LocationFailure.serviceDisabled =>
          'El GPS está desactivado. Actívalo en ajustes del dispositivo.',
        LocationFailure.unavailable ||
        null =>
          'No se pudo leer la ubicación. Intenta de nuevo.',
      };

  Future<void> _handleLocationAction() async {
    if (_locationFailure == LocationFailure.permissionDeniedForever) {
      await openAppSettings();
      return;
    }
    if (_locationFailure == LocationFailure.serviceDisabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    await _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codigoCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isConnecting = true);

    final provider = context.read<CentinelaProvider>();
    await provider.saveAndConnect(
      connectionName: _nameCtrl.text.trim(),
      codigoNodo: _codigoCtrl.text.trim(),
      latitud: double.parse(_latCtrl.text.trim()),
      longitud: double.parse(_lngCtrl.text.trim()),
      brokerHost: _hostCtrl.text.trim(),
      brokerPort: int.parse(_portCtrl.text.trim()),
      eventDurationSeconds: _durationSeconds,
      thresholdDb: _thresholdDb,
    );

    if (!mounted) return;
    setState(() => _isConnecting = false);

    // Navegar a HomeScreen reemplazando la ruta actual
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => const HomeScreen(),
        transitionsBuilder: (context, anim, a2, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    _buildHeader(),
                    const SizedBox(height: 36),

                    // ── Formulario ──────────────────────────────────────────
                    _buildForm(),
                    const SizedBox(height: 32),

                    // ── Botón ───────────────────────────────────────────────
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Ícono con glow
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4F8EF7), Color(0xFF7B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F8EF7).withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.sensors, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 20),
        const Text(
          'CENTINELA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Configuración de conexión MQTT',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF141929),
        border: Border.all(color: const Color(0xFF2A3352), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Identidad del Nodo'),
            const SizedBox(height: 14),
            _buildField(
              id: 'field_connection_name',
              label: 'Nombre de conexión',
              hint: 'ej. CENTINELA',
              controller: _nameCtrl,
              icon: Icons.badge_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildField(
              id: 'field_codigo_nodo',
              label: 'Código del nodo',
              hint: 'ej. NODO-001',
              controller: _codigoCtrl,
              icon: Icons.qr_code_2_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Este código debe coincidir con el nodo registrado en el Centro de Comando',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Ubicación'),
            const SizedBox(height: 14),
            _buildLocationButton(),
            if (_locationMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _locationMessage!,
                  style: TextStyle(
                    color: _locationMessage!.contains('correctamente')
                        ? const Color(0xFF5CC98B)
                        : const Color(0xFFE05C5C),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildField(
              id: 'field_latitud',
              label: 'Latitud',
              hint: 'ej. -0.18',
              controller: _latCtrl,
              icon: Icons.location_on_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                final n = double.tryParse(v.trim());
                if (n == null || n < -5 || n > 2) {
                  return 'Latitud inválida (-5 a 2)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildField(
              id: 'field_longitud',
              label: 'Longitud',
              hint: 'ej. -78.47',
              controller: _lngCtrl,
              icon: Icons.explore_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                final n = double.tryParse(v.trim());
                if (n == null || n < -92 || n > -75) {
                  return 'Longitud inválida (-92 a -75)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _sectionLabel('Broker MQTT'),
            const SizedBox(height: 14),
            _buildField(
              id: 'field_broker_host',
              label: 'Dirección IP / Host',
              hint: 'ej. 192.168.1.27',
              controller: _hostCtrl,
              icon: Icons.router_outlined,
              keyboardType: TextInputType.url,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildField(
              id: 'field_broker_port',
              label: 'Puerto',
              hint: 'ej. 1883',
              controller: _portCtrl,
              icon: Icons.electrical_services_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                final n = int.tryParse(v.trim());
                if (n == null || n < 1 || n > 65535) {
                  return 'Puerto inválido (1–65535)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _sectionLabel('Grabación de Audio'),
            const SizedBox(height: 16),
            _buildDurationSlider(),
            const SizedBox(height: 16),
            _buildThresholdSlider(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [Color(0xFF4F8EF7), Color(0xFF7B5CF6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF8BA4D4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  String get _locationButtonLabel {
    if (_isFetchingLocation) return 'Obteniendo ubicación...';
    return switch (_locationFailure) {
      LocationFailure.permissionDeniedForever => 'Abrir ajustes de permisos',
      LocationFailure.serviceDisabled => 'Activar GPS',
      _ => 'Obtener ubicación actual',
    };
  }

  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        key: const Key('btn_get_location'),
        onPressed: _isFetchingLocation ? null : _handleLocationAction,
        icon: _isFetchingLocation
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location, size: 20),
        label: Text(
          _locationButtonLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4F8EF7),
          side: const BorderSide(color: Color(0xFF4F8EF7)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF0E1320),
        ),
      ),
    );
  }

  Widget _buildField({
    required String id,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: Key(id),
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.22), fontSize: 13),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF4F8EF7), size: 20),
        filled: true,
        fillColor: const Color(0xFF0E1320),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3352), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F8EF7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE05C5C), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE05C5C), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFE05C5C), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _buildDurationSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1320),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3352), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFF4F8EF7), size: 20),
                const SizedBox(width: 10),
                Text(
                  'Duración del evento de audio',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F8EF7), Color(0xFF7B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_durationSeconds s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF4F8EF7),
              inactiveTrackColor: const Color(0xFF2A3352),
              thumbColor: const Color(0xFF7B5CF6),
              overlayColor: const Color(0xFF4F8EF7).withValues(alpha: 0.2),
              valueIndicatorColor: const Color(0xFF7B5CF6),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              key: const Key('slider_duration'),
              value: _durationSeconds.toDouble(),
              min: 3,
              max: 5,
              divisions: 2,
              label: '$_durationSeconds s',
              onChanged: (v) => setState(() => _durationSeconds = v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('3 s', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                Text('4 s', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                Text('5 s', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1320),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3352), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.volume_up_outlined, color: Color(0xFF4F8EF7), size: 20),
                const SizedBox(width: 10),
                Text(
                  'Umbral de sonido',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F8EF7), Color(0xFF7B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_thresholdDb.toStringAsFixed(0)} dB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF4F8EF7),
              inactiveTrackColor: const Color(0xFF2A3352),
              thumbColor: const Color(0xFF7B5CF6),
              overlayColor: const Color(0xFF4F8EF7).withValues(alpha: 0.2),
              valueIndicatorColor: const Color(0xFF7B5CF6),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              key: const Key('slider_threshold'),
              value: _thresholdDb,
              min: 30,
              max: 90,
              divisions: 60,
              label: '${_thresholdDb.toStringAsFixed(0)} dB',
              onChanged: (v) => setState(() => _thresholdDb = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('30 dB', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                Text('60 dB', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                Text('90 dB', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: _isConnecting
            ? const LinearGradient(colors: [Color(0xFF2A3352), Color(0xFF2A3352)])
            : const LinearGradient(
                colors: [Color(0xFF4F8EF7), Color(0xFF7B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: _isConnecting
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF4F8EF7).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        key: const Key('btn_save_connect'),
        onPressed: _isConnecting ? null : _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isConnecting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sensors, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Guardar y Conectar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
