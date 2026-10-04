import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../models/shot.dart';

class ConnectionHandler {
  Socket? socket;
  bool isConnected = false;
  DateTime? lastKeepAlive;
  String incomingJSON = "";
  String? _connectedIp;
  Timer? _linkWatch;
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

  /// Completed when the target sends its `freETarget ...` startup line.
  Completer<void>? _startup;

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
      final startup = Completer<void>();
      _startup = startup;

      final connected = socket!;
      connected.listen(
        _handleIncomingData,
        onError: (error) {
          if (socket != connected) return;
          _handleError(error);
        },
        onDone: () {
          if (socket != connected) return;
          _handleDisconnection();
        },
      );

      // A TCP handshake is not enough. The icon stays disconnected until the
      // target sends the startup line it prints after a real connection.
      await startup.future.timeout(const Duration(seconds: 4));
      _connectedIp = ip;
      _startLinkWatch();
      onMessage('Target ready');
    } on TimeoutException {
      await disconnect(quiet: true);
      onMessage('No startup message from the target.');
    } catch (e) {
      isConnected = false;
      if (socket != null) {
        await disconnect(quiet: true);
      }
      onMessage('Connection failed: ${e.toString()}');
    } finally {
      _startup = null;
    }
  }

  void _handleIncomingData(List<int> data) {
    final received = utf8.decode(data, allowMalformed: true);

    onMessage('Original message: $received');

    if (received.contains('freETarget') &&
        _startup != null &&
        !_startup!.isCompleted) {
      isConnected = true;
      lastKeepAlive = DateTime.now();
      _startup!.complete();
    }

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
    if (_startup != null && !_startup!.isCompleted) {
      _startup!.completeError(error is Object ? error : StateError('$error'));
    }
    isConnected = false;
    onMessage('Connection error: ${error.toString()}');
    onDisconnect();
  }

  void _handleDisconnection() {
    if (_startup != null && !_startup!.isCompleted) {
      _startup!.completeError(const SocketException('closed'));
    }
    // disconnect() already reported a close this side started.
    if (!isConnected) return;
    isConnected = false;
    onMessage('Disconnected from ETS');
    onDisconnect();
  }

  Future<void> disconnect({bool quiet = false}) async {
    _stopLinkWatch();
    final old = socket;
    socket = null;
    _connectedIp = null;
    isConnected = false;
    old?.destroy();
    if (!quiet) onMessage('Disconnected from ETS');
  }

  /// The socket often stays open on paper after the target is powered off.
  /// The iPad's own address on the target network is the thing that actually
  /// disappears, so that is what this checks.
  void _startLinkWatch() {
    _linkWatch?.cancel();
    _linkWatch = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkTargetNetwork();
    });
  }

  void _stopLinkWatch() {
    _linkWatch?.cancel();
    _linkWatch = null;
  }

  Future<void> _checkTargetNetwork() async {
    final ip = _connectedIp;
    if (!isConnected || ip == null) return;
    final present = await _ipadIsOnTargetNetwork(ip);
    if (!isConnected || _connectedIp != ip) return;
    if (present) return;

    onMessage('Target Wi-Fi is gone.');
    await disconnect(quiet: true);
    onDisconnect();
  }

  Future<bool> _ipadIsOnTargetNetwork(String targetIp) async {
    final parts = targetIp.split('.');
    if (parts.length != 4) return true;
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}.';

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.address.startsWith(prefix)) return true;
        }
      }
    } catch (_) {
      // If the interfaces cannot be read, leave the current state alone.
      return true;
    }
    return false;
  }

  void sendSettings(Map<String, dynamic> settings) {
    if (isConnected) {
      final settingsJson = jsonEncode(settings);
      socket?.write('{$settingsJson}');
      onMessage('Settings applied: $settingsJson');
    }
  }

  /// Asks the target to run its startup again. The socket stays open long
  /// enough for the Arduino to read the command, then this side closes it.
  /// The iPad stays joined to the target Wi-Fi, so the old socket would
  /// otherwise keep looking connected after the ESP restarts.
  Future<void> resetTarget() async {
    if (!isConnected || socket == null) {
      onMessage('Connect to the target before resetting it.');
      return;
    }

    socket!.write('{"RESET":0}');
    await socket!.flush();
    onMessage('Reset sent. Waiting for the target to read it.');
    await Future.delayed(const Duration(seconds: 1));
    await disconnect();
    onDisconnect();
  }

  void dispose() {
    _stopLinkWatch();
    socket?.destroy();
  }
}