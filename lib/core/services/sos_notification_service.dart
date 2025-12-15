import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:vibration/vibration.dart';

class SOSNotificationService {
  static final SOSNotificationService _instance =
      SOSNotificationService._internal();
  factory SOSNotificationService() => _instance;
  SOSNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _vibrationTimer;
  bool _isSOSActive = false;

  // Settings keys
  static const String _soundEnabledKey = 'sos_sound_enabled';
  static const String _vibrationEnabledKey = 'sos_vibration_enabled';

  Future<void> initialize() async {
    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request notification permission
    await Permission.notification.request();

    // Request exact alarm permission (Android 12+)
    // Only available on Android 12+, will be ignored on older versions
    try {
      await Permission.scheduleExactAlarm.request();
    } catch (e) {
      debugPrint('Schedule exact alarm permission not available: $e');
    }
  }

  Future<void> setMasterNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_soundEnabledKey, enabled);
    await prefs.setBool(_vibrationEnabledKey, enabled);

    if (!enabled && _isSOSActive) {
      // Nếu đang kêu mà tắt setting -> Dừng ngay
      await _audioPlayer.stop();
      _vibrationTimer?.cancel();
      await Vibration.cancel();
    } else if (enabled && _isSOSActive) {
      // Nếu đang SOS (nhưng im lặng) mà bật setting -> Kêu lại ngay
      await _startContinuousAlerts();
    }
  }

  // Hàm check xem có đang bật master setting không (dùng để load initial state)
  Future<bool> isMasterNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Mặc định là true
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> showSOSNotification() async {
    if (_isSOSActive) return;
    _isSOSActive = true;

    // Show high priority notification
    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'sos_channel',
      'Emergency SOS',
      channelDescription: 'Critical emergency alerts',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // Cannot be dismissed
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        'Người thân của bạn vừa gửi tín hiệu cầu cứu SOS. Vui lòng kiểm tra ngay lập tức!',
        contentTitle: 'CẢNH BÁO KHẨN CẤP SOS',
        summaryText: 'Guardian Connect',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
      sound: 'alarm.aiff',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'CẢNH BÁO KHẨN CẤP SOS',
      'Người thân đang cần sự trợ giúp khẩn cấp!',
      details,
    );

    // Start continuous sound and vibration
    await _startContinuousAlerts();
  }

  Future<void> _startContinuousAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    final vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;

    // Start continuous sound
    if (soundEnabled) {
      await _startContinuousSound();
    }

    // Start continuous vibration
    if (vibrationEnabled) {
      await _startContinuousVibration();
    }
  }

  Future<void> _startContinuousSound() async {
    try {
      // Set player to loop mode
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Set volume to maximum
      await _audioPlayer.setVolume(1.0);

      // Set audio mode to override silent mode
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );

      await _audioPlayer.play(
        AssetSource(
          'sounds/zapsplat_science_fiction_alarm_small_bright_warning_114821.mp3',
        ),
      );

      debugPrint('Alarm sound started (looping)');
    } catch (e) {
      debugPrint('Error playing sound: $e');

      // Fallback: Try to use system alarm sound
      try {
        await _audioPlayer.play(
          DeviceFileSource('/system/media/audio/alarms/Alarm_Classic.ogg'),
        );
        debugPrint('Using system alarm sound as fallback');
      } catch (e2) {
        debugPrint('Fallback also failed: $e2');
      }
    }
  }

  Future<void> _startContinuousVibration() async {
    if (await Vibration.hasVibrator()) {
      // Pattern: [wait, vibrate, wait, vibrate, ...]
      // Duration in milliseconds
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (
        timer,
      ) async {
        if (_isSOSActive) {
          await Vibration.vibrate(
            pattern: [0, 500, 200, 500, 200, 500], // Strong vibration pattern
            intensities: [0, 255, 0, 255, 0, 255], // Max intensity
          );
        }
      });
    }
  }

  Future<void> cancelSOSNotification() async {
    _isSOSActive = false;

    // Cancel notification
    await _notifications.cancel(0);

    // Stop sound
    await _audioPlayer.stop();

    // Stop vibration
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    await Vibration.cancel();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to alert screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Settings methods
  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);

    if (!enabled && _isSOSActive) {
      await _audioPlayer.stop();
    } else if (enabled && _isSOSActive) {
      await _startContinuousSound();
    }
  }

  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);

    if (!enabled && _isSOSActive) {
      _vibrationTimer?.cancel();
      await Vibration.cancel();
    } else if (enabled && _isSOSActive) {
      await _startContinuousVibration();
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _vibrationTimer?.cancel();
    await Vibration.cancel();
  }
}
