enum DeviceRole { host, client }

enum PlatformType { windows, android }

class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final DeviceRole role;
  final PlatformType platform;
  final String appVersion;
  final String osVersion;
  
  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.role,
    required this.platform,
    required this.appVersion,
    required this.osVersion,
  });
  
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      role: DeviceRole.values.firstWhere(
        (e) => e.name == json['role'],
      ),
      platform: PlatformType.values.firstWhere(
        (e) => e.name == json['platform'],
      ),
      appVersion: json['appVersion'] as String,
      osVersion: json['osVersion'] as String,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'role': role.name,
    'platform': platform.name,
    'appVersion': appVersion,
    'osVersion': osVersion,
  };
  
  @override
  String toString() {
    return 'DeviceInfo(deviceName: $deviceName, role: $role, platform: $platform)';
  }
}
