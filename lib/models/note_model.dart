class NoteModel {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });


  factory NoteModel.fromMap(Map<String, dynamic> map){
    return NoteModel(
        id: map['id'] as String? ?? "",
        title: map['title'] as String? ?? "",
        description: map["description"] as String? ?? "",
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String)
    );
  }

  Map<String, dynamic> toMap(){
    return{
      'id' : id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt' : updatedAt.toIso8601String(),

    };
  }

  NoteModel copyWith({
    String? title,
    String? description,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
