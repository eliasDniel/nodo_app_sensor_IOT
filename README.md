# CENTINELA — Nodo Audio

App Flutter para **monitoreo de audio en tiempo real**. Funciona como un nodo del sistema CENTINELA: escucha el micrófono del dispositivo, detecta sonidos por encima de un umbral y envía cada evento al broker MQTT (metadatos + clip de audio WAV).

## ¿Qué hace?

- Se conecta a un broker **MQTT** (Mosquitto u otro).
- Captura audio continuo del micrófono.
- Al superar el umbral (~60 dB), graba un clip de **6 segundos** (2 s antes + 4 s después del disparo).
- Publica en dos tópicos:
  - `centinela/meta` — JSON con id del evento, timestamp y nivel de audio.
  - `centinela/audio` — archivo WAV del clip.

Si el broker no está disponible, los eventos se guardan localmente y se reenvían al reconectar.

## Uso rápido

1. **Configura el broker** en `lib/config/centinela_config.dart`:
   - `brokerHost`: IP del PC con Mosquitto (en emulador Android usa `10.0.2.2`).
   - `brokerPort`: `1883` por defecto.

2. **Ejecuta la app** (`flutter run` o instala el APK release).

3. Concede el **permiso de micrófono** cuando lo pida.

4. Pulsa **Encender Nodo** para iniciar la escucha.

5. Revisa el **log de actividad** y los indicadores de estado (MQTT, nodo, micrófono, dB).

6. Para detener, pulsa **Apagar Nodo**.

## Verificar eventos en el PC

Con Mosquitto en el mismo equipo:

```cmd
mosquitto_sub.exe -h localhost -t "centinela/#" -v
```

## Requisitos

- Flutter SDK
- Broker MQTT accesible desde el dispositivo (misma red WiFi o emulador con `10.0.2.2`)
- Android con permiso de micrófono

## Compilar APK release

```cmd
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.
