// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classification_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassificationNode _$ClassificationNodeFromJson(Map<String, dynamic> json) {
  return ClassificationNode(
    id: json['id'] as String,
    projectId: json['projectId'] as int,
    parentId: json['parentId'] as String?,
    rank: json['rank'] as String,
    name: json['name'] as String,
    normalizedName: json['normalizedName'] as String,
    content: json['content'] as String? ?? '',
    iconKey: json['iconKey'] as String? ?? 'folder',
    colorValue: json['colorValue'] as int? ?? 0xFF6366F1,
    childrenOrder: (json['childrenOrder'] as List?)?.cast<String>() ?? [],
    createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    updatedAt: json['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );
}

Map<String, dynamic> _$ClassificationNodeToJson(ClassificationNode instance) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'parentId': instance.parentId,
  'rank': instance.rank,
  'name': instance.name,
  'normalizedName': instance.normalizedName,
  'content': instance.content,
  'iconKey': instance.iconKey,
  'colorValue': instance.colorValue,
  'childrenOrder': instance.childrenOrder,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};