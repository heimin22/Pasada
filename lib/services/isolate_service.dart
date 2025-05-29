import 'dart:isolate';
import '../utils/compute_helpers.dart';
import '../models/trip.dart';

/// A service to offload JSON parsing of trips into a long-lived isolate.
class TripIsolateService {
  Isolate? _isolate;
  ReceivePort? _mainReceivePort;
  SendPort? _isolateSendPort;

  /// Starts the isolate and sets up communication channels.
  Future<void> start() async {
    _mainReceivePort = ReceivePort();
    _mainReceivePort!.listen(_handleMessage);
    _isolate = await Isolate.spawn(_entryPoint, _mainReceivePort!.sendPort);
  }

  /// Entry point for the spawned isolate.
  static void _entryPoint(SendPort mainSendPort) {
    final port = ReceivePort();
    // Send the isolate's SendPort to the main isolate.
    mainSendPort.send(port.sendPort);

    // Listen for incoming messages: [jsonString, replyPort]
    port.listen((dynamic message) {
      final String jsonStr = message[0] as String;
      final SendPort replyPort = message[1] as SendPort;

      // Perform heavy parsing
      final List<Trip> trips = parseTrips(jsonStr);

      // Send the result back.
      replyPort.send(trips);
    });
  }

  void _handleMessage(dynamic message) {
    if (message is SendPort) {
      _isolateSendPort = message;
    }
  }

  /// Parses [jsonStr] in the background isolate and returns the result.
  Future<List<Trip>> parseTripsInBackground(String jsonStr) async {
    final receivePort = ReceivePort();
    _isolateSendPort?.send([jsonStr, receivePort.sendPort]);
    final result = await receivePort.first as List<Trip>;
    receivePort.close();
    return result;
  }

  /// Stops the isolate and cleans up.
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _mainReceivePort?.close();
  }
}
