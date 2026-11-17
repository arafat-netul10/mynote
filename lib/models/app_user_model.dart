class AppUserModel {

  final String id;
  final String email;
  final String displayName;

  const AppUserModel({required this.id, required this.email, required this.displayName,});

  factory AppUserModel.fromMap(Map<String, dynamic> map){
    return AppUserModel(
        id: map["id"] as String? ?? "",
        email: map["email"] as String? ?? "",
        displayName: map["displayName"] as String? ?? "",

      );
  }

  Map<String, dynamic> toMap(){

    return {
      'id': id,
      'email': email,
      'displayName': displayName
    };
}

}