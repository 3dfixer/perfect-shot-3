import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../models/shot.dart';

class ConnectionHandler {
  Socket? socket;
  bool isConnected = false;
  DateTime? lastKeepAlive;
  String incomingJSON = "";
  final void Function(String) onMessage;
  final void Function(Shot) onShot;
  final void Function() onDisconnect;

  ConnectionHandler({
    required this.onMessage,
    required this.onShot,
    required this.onDisconnect,
  });

  /// Target type used to score incoming shots. Can be changed while connected.
  TargetType targetType = TargetType.airPistol;

  Future<void> connect(String ip, int port, TargetType targetType) async {
    this.targetType = targetType;
    if (isConnected) {
      await disconnect();
      return;
    }

    try {
      onMessage('Connecting to ETS...');
      socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      isConnected = true;
      lastKeepAlive = DateTime.now();
      onMessage('Connected to ETS');

      socket!.listen(
        _handleIncomingData,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
    } catch (e) {
      isConnected = false;
      onMessage('Connection failed: ${e.toString()}');
    }
  }

  void _handleIncomingData(List<int> data) {
    final received = utf8.decode(data, allowMalformed: true);

    onMessage('Original message: $received');

    lastKeepAlive = DateTime.now();
    incomingJSON += received;
    incomingJSON = incomingJSON.replaceAll(", ,", ",,").replaceAll(",,", ",");

    int indexOpenBracket = 0;
    int indexClosedBracket = 0;

    try {
      // A single packet may contain several messages, or only part of one,
      // so keep extracting complete {...} messages until none are left.
      while (true) {
        indexOpenBracket = incomingJSON.indexOf('{');
        if (indexOpenBracket < 0) {
          // No message start in the buffer, so anything left is junk.
          incomingJSON = "";
          break;
        }

        indexClosedBracket = incomingJSON.indexOf('}', indexOpenBracket);
        if (indexClosedBracket < 0) {
          // Incomplete message; wait for more data.
          incomingJSON = incomingJSON.substring(indexOpenBracket);
          break;
        }

        final message = incomingJSON.substring(
            indexOpenBracket, indexClosedBracket + 1);
        incomingJSON = incomingJSON.substring(indexClosedBracket + 1);
        onMessage('json message: $message');

        if (message.contains('KEEP_ALIVE')) {
          onMessage('Keep alive received');
        } else if (message.contains('shot')) {
          _processShotData(message, targetType);
        }
      }

      onMessage('Remaining JSON buffer: $incomingJSON');
    } catch (e) {
      onMessage('Error in JSON buffer: $incomingJSON');
      onMessage('JSON parsing indexes - Start: $indexOpenBracket, End: $indexClosedBracket');
      onMessage('Error processing data: $e');
      incomingJSON = "";
    }
  }

  void _processShotData(String message, TargetType targetType) {
    try {
      final json = jsonDecode(message);
      final shot = Shot.fromJson(json, targetType);
      onShot(shot);
    } catch (e) {
      onMessage('Error processing shot: $e');
    }
  }

  void _handleError(error) {
    isConnected = false;
    onMessage('Connection error: ${error.toString()}');
    onDisconnect();
  }

  void _handleDisconnection() {
    isConnected = false;
    onMessage('Disconnected from ETS');
    onDisconnect();
  }

  Future<void> disconnect() async {
    socket?.destroy();
    isConnected = false;
    onMessage('Disconnected from ETS');
  }

  void sendSettings(Map<String, dynamic> settings) {
    if (isConnected) {
      final settingsJson = jsonEncode(settings);
      socket?.write('{$settingsJson}');
      onMessage('Settings applied: $settingsJson');
    }
  }

  void dispose() {
    socket?.destroy();
  }
}