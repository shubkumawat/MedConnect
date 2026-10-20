class FamilyMemberModel {
  final String id;
  final String name;
  final String relation;
  final String bloodGroup;
  final String? avatar;
  final bool isSelf;

  FamilyMemberModel({
    required this.id,
    required this.name,
    required this.relation,
    required this.bloodGroup,
    this.avatar,
    this.isSelf = false,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) => FamilyMemberModel(
    id: json['id'],
    name: json['name'],
    relation: json['relation'],
    bloodGroup: json['bloodGroup'],
    avatar: json['avatar'],
    isSelf: json['isSelf'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relation': relation,
    'bloodGroup': bloodGroup,
    'avatar': avatar,
    'isSelf': isSelf,
  };
}
