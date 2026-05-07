import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  late MqttClient client;
  bool isConnected = false;
  final Map<String, List<Function(String)>> _topicListeners = {};

  Future<void> connect() async {
    if (isConnected) return; // Évite de se reconnecter plusieurs fois

    final String serverIp = '172.20.10.7'; // ← VRAIE IP DE TON PC (Wi-Fi)

    if (kIsWeb) {
      // Pour le Web, on doit utiliser les WebSockets et le port 9001
      client = MqttBrowserClient('ws://$serverIp', 'flutter_web_client_${DateTime.now().millisecondsSinceEpoch}');
      client.port = 9001; 
      client.websocketProtocols = ['mqtt'];
    } else {
      // Pour Windows/Android/iOS, on utilise TCP et le port 1883
      client = MqttServerClient(serverIp, 'flutter_app_client_${DateTime.now().millisecondsSinceEpoch}');
      client.port = 1883;
    }

    client.logging(on: true);
    client.keepAlivePeriod = 20;

    final connOpts = MqttConnectMessage()
        .withClientIdentifier('flutter_dashboard_123')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connOpts;

    try {
      await client.connect();
      isConnected = true;
      print('✅ Connecté au MQTT du PC (Mode: ${kIsWeb ? "WebSockets" : "TCP"})');

      // Écoute globale des messages
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> c) {
        final MqttPublishMessage rec = c[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(rec.payload.message);
        final topic = c[0].topic;
        
        // Dispatche le message reçu à tous les widgets qui écoutent ce topic
        if (_topicListeners.containsKey(topic)) {
          for (var callback in _topicListeners[topic]!) {
            callback(payload);
          }
        }
      });

      // Si des widgets ont demandé à souscrire AVANT que la connexion soit finie
      for (var topic in _topicListeners.keys) {
        client.subscribe(topic, MqttQos.atLeastOnce);
      }

    } catch (e) {
      print('❌ Erreur de connexion MQTT: $e');
      client.disconnect();
      isConnected = false;
    }
  }

  void subscribe(String topic, Function(String) onMessage) {
    if (!_topicListeners.containsKey(topic)) {
      _topicListeners[topic] = [];
      // Si on est déjà connecté, on dit au broker MQTT qu'on veut écouter
      if (isConnected) {
         client.subscribe(topic, MqttQos.atLeastOnce);
      }
    }
    _topicListeners[topic]!.add(onMessage);
  }

  void publish(String topic, String message) {
    if (!isConnected) {
      print("Erreur: Impossible de publier, client non connecté.");
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }
}
