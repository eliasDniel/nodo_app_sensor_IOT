import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/centinela_config.dart';
import '../../models/connection_status.dart';
import '../../models/node_status.dart';
import '../../providers/centinela_provider.dart';
import '../widgets/activity_log.dart';
import '../widgets/status_badge.dart';
import 'config_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CENTINELA — Nodo Audio'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            key: const Key('btn_settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () => _goToConfig(context),
          ),
        ],
      ),
      body: Consumer<CentinelaProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CentinelaConfig.connectionName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Código: ${CentinelaConfig.codigoNodo}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          'Ubicación: ${CentinelaConfig.latitud.toStringAsFixed(4)}, ${CentinelaConfig.longitud.toStringAsFixed(4)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          'Broker: ${CentinelaConfig.brokerHost}:${CentinelaConfig.brokerPort}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        const Divider(height: 24),
                        StatusBadge(
                          label: 'MQTT',
                          value: _mqttLabel(provider.connectionStatus),
                          color: _mqttColor(provider.connectionStatus),
                        ),
                        StatusBadge(
                          label: 'Nodo',
                          value: _nodeLabel(provider.nodeStatus),
                          color: provider.nodeStatus == NodeStatus.active
                              ? Colors.green
                              : Colors.grey,
                        ),
                        StatusBadge(
                          label: 'Micrófono',
                          value:
                              '${_micLabel(provider.micStatus)} (${provider.currentDb.toStringAsFixed(1)} dB)',
                          color: provider.micStatus == MicStatus.listening
                              ? Colors.blue
                              : provider.micStatus == MicStatus.error
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Eventos detectados: ${provider.eventCount}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (provider.queue.pendingCount > 0)
                          Text(
                            'En cola: ${provider.queue.pendingCount}',
                            style: TextStyle(color: Colors.orange.shade700),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('btn_encender_nodo'),
                        onPressed: provider.nodeStatus == NodeStatus.inactive
                            ? provider.encenderNodo
                            : null,
                        icon: const Icon(Icons.mic),
                        label: const Text('Encender Nodo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('btn_apagar_nodo'),
                        onPressed: provider.nodeStatus == NodeStatus.active
                            ? provider.apagarNodo
                            : null,
                        icon: const Icon(Icons.mic_off),
                        label: const Text('Apagar Nodo'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Log de actividad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: ActivityLog(logs: provider.logs),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _goToConfig(BuildContext context) async {
    final provider = context.read<CentinelaProvider>();
    await provider.disconnectAll();

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a1, a2) => const ConfigScreen(),
        transitionsBuilder: (ctx, anim, a2, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  String _mqttLabel(ConnectionStatus status) => switch (status) {
        ConnectionStatus.connected => 'Conectado',
        ConnectionStatus.disconnected => 'Desconectado',
        ConnectionStatus.reconnecting => 'Reconectando',
      };

  Color _mqttColor(ConnectionStatus status) => switch (status) {
        ConnectionStatus.connected => Colors.green,
        ConnectionStatus.disconnected => Colors.red,
        ConnectionStatus.reconnecting => Colors.orange,
      };

  String _nodeLabel(NodeStatus status) => switch (status) {
        NodeStatus.active => 'Activo',
        NodeStatus.inactive => 'Inactivo',
      };

  String _micLabel(MicStatus status) => switch (status) {
        MicStatus.listening => 'Escuchando',
        MicStatus.off => 'Apagado',
        MicStatus.error => 'Error',
      };
}
