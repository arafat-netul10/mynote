
import 'base_model.dart';

class AppUserModel extends BaseModel {
  final String email;
  final String displayName;

  const AppUserModel({
    required super.id,
    required this.email,
    required this.displayName,
  });

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
    };
  }
}
