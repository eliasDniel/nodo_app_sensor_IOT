import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/centinela_provider.dart';
import 'ui/screens/config_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CentinelaApp());
}

class CentinelaApp extends StatelessWidget {
  const CentinelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CentinelaProvider()..init(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CENTINELA Nodo Audio',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        // La app siempre inicia en ConfigScreen para ingresar o confirmar la conexión
        home: const ConfigScreen(),
      ),
    );
  }
}
