// lib/models/profile_settings.dart
class ProfileSettings {
  final int? id;
  final String firstName;
  final String lastName;
  final String userName;
  final String
      displayNameOption; // 'firstName', 'lastName', 'userName', 'custom'
  final String customName;

  ProfileSettings({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.userName,
    required this.displayNameOption,
    this.customName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'userName': userName,
      'displayNameOption': displayNameOption,
      'customName': customName,
    };
  }

  static ProfileSettings fromMap(Map<String, dynamic> map) {
    return ProfileSettings(
      id: map['id'],
      firstName: map['firstName'] ?? 'User',
      lastName: map['lastName'] ?? '',
      userName: map['userName'] ?? 'User',
      displayNameOption: map['displayNameOption'] ?? 'userName',
      customName: map['customName'] ?? '',
    );
  }

  // Helper method to get the display name based on the selected option
  String getDisplayName() {
    switch (displayNameOption) {
      case 'firstName':
        return firstName.isNotEmpty ? firstName : 'User';
      case 'lastName':
        return lastName.isNotEmpty ? lastName : 'User';
      case 'userName':
        return userName.isNotEmpty ? userName : 'User';
      case 'custom':
        return customName.isNotEmpty
            ? customName
            : (userName.isNotEmpty ? userName : 'User');
      default:
        return 'User';
    }
  }

  // Create a copy with modified properties
  ProfileSettings copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? userName,
    String? displayNameOption,
    String? customName,
  }) {
    return ProfileSettings(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userName: userName ?? this.userName,
      displayNameOption: displayNameOption ?? this.displayNameOption,
      customName: customName ?? this.customName,
    );
  }
}
