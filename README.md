# CENTINELA — Nodo Audio

App Flutter para **monitoreo de audio en tiempo real**. Funciona como un nodo del sistema CENTINELA (UNEMI): escucha el micrófono del dispositivo, detecta sonidos por encima de un umbral y envía cada evento al broker MQTT en un único mensaje JSON (metadatos + clip de audio WAV en Base64).

## Prerequisito

El nodo debe **registrarse antes** en el backend del Centro de Comando y obtener un **código de nodo**. Ese mismo código se ingresa en la app (pantalla de configuración) para identificarse ante el sistema.

## ¿Qué hace?

- Se conecta a un broker **MQTT** (Mosquitto u otro) usando el código del nodo como client ID.
- Captura audio continuo del micrófono.
- Al superar el umbral configurado (30–90 dB, default 60 dB), graba un clip de **3–5 segundos** (1 s antes + resto después del disparo).
- Publica en el topic **`centinela/evento`** un JSON con metadata, coordenadas y audio codificado en Base64.

Si el broker no está disponible, los eventos se guardan localmente y se reenvían al reconectar.

## Payload MQTT (`centinela/evento`)

```json
{
  "codigo_nodo": "NODO-001",
  "latitud": -0.1807,
  "longitud": -78.4678,
  "timestamp": 1781325741296,
  "duracion": 4,
  "evento_id": "196844ff-3e1e-47c0-8c3a-e48c566fb90a",
  "nivel_audio": 82.41,
  "audio_b64": "UklGRi..."
}
```

## Uso rápido

1. Registra el nodo en el Centro de Comando y anota su **código**.
2. Abre la app e ingresa en **Configuración**:
   - Código del nodo (debe coincidir con el registro)
   - Latitud y longitud (Ecuador: lat -5…2, lng -92…-75)
   - Host y puerto del broker MQTT (`1883` por defecto; en emulador Android usa `10.0.2.2` para localhost)
3. Pulsa **Guardar y Conectar**.
4. Concede el **permiso de micrófono** cuando lo pida.
5. Pulsa **Encender Nodo** para iniciar la escucha.
6. Revisa el **log de actividad** y los indicadores de estado (MQTT, nodo, micrófono, dB).
7. Para detener, pulsa **Apagar Nodo**.

## Verificar eventos en el PC

Con Mosquitto en el mismo equipo:

```cmd
mosquitto_sub.exe -h localhost -t "centinela/evento" -v
```

## Requisitos

- Flutter SDK
- Nodo registrado previamente en el Centro de Comando (código válido)
- Broker MQTT accesible desde el dispositivo (misma red WiFi o emulador con `10.0.2.2`)
- Android con permiso de micrófono

## Compilar APK release

```cmd
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.
