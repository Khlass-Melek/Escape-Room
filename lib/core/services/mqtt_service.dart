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
    if (isConnected) return;

    final String serverIp = '172.20.10.7';

    if (kIsWeb) {
      client = MqttBrowserClient('ws://$serverIp', 'esc_dash_${DateTime.now().millisecondsSinceEpoch}');
      client.port = 1883;
      client.websocketProtocols = ['mqtt'];
    } else {
      client = MqttServerClient(serverIp, 'flutter_app_client_${DateTime.now().millisecondsSinceEpoch}');
      client.port = 1883;
    }

    client.logging(on: true);
    client.keepAlivePeriod = 20;

    final connOpts = MqttConnectMessage()
        .withClientIdentifier('escaperoom_dashboard_${DateTime.now().millisecondsSinceEpoch}')
        .startClean();

    client.connectionMessage = connOpts;

    try {
      await client.connect();
      isConnected = true;
      print('✅ Connecté au MQTT du PC (Mode: ${kIsWeb ? "WebSockets" : "TCP"})');

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> c) {
        final MqttPublishMessage rec = c[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(rec.payload.message);
        final topic = c[0].topic;
        
        if (_topicListeners.containsKey(topic)) {
          for (var callback in _topicListeners[topic]!) {
            callback(payload);
          }
        }
      });

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
