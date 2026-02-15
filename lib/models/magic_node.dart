import 'dart:typed_data';

import 'package:hive/hive.dart';

part 'magic_node.g.dart';

@HiveType(typeId: 8)
class MagicNode extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int systemKey;

  @HiveField(2)
  String? parentId;

  @HiveField(3)
  String type;

  @HiveField(4)
  String title;

  @HiveField(5)
  String iconKey;

  @HiveField(6)
  int colorValue;

  @HiveField(7)
  String content;

  @HiveField(8)
  List<MagicAttribute> attributes;

  @HiveField(9)
  List<String> childrenOrder;

  @HiveField(10)
  int createdAt;

  @HiveField(11)
  int updatedAt;

  @HiveField(12)
  List<MagicImage>? _images;

  List<MagicImage> get images {
    _images ??= [];
    return _images!;
  }

  set images(List<MagicImage> value) {
    _images = List<MagicImage>.from(value);
  }

  MagicNode({
    required this.id,
    required this.systemKey,
    required this.parentId,
    required this.type,
    required this.title,
    required this.iconKey,
    required this.colorValue,
    required this.content,
    required this.attributes,
    required this.childrenOrder,
    List<MagicImage>? images,
    int? createdAt,
    int? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch,
       _images = List<MagicImage>.from(images ?? []);

  void updateTimestamp() {
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }
}

@HiveType(typeId: 22)
class MagicImage extends HiveObject {
  @HiveField(0)
  Uint8List imageData;

  @HiveField(1)
  String caption;

  @HiveField(2)
  String state;

  @HiveField(3)
  double? aspectRatio;

  MagicImage({
    required this.imageData,
    required this.caption,
    required this.state,
    this.aspectRatio,
  });
}

@HiveType(typeId: 9)
class MagicAttribute extends HiveObject {
  @HiveField(0)
  String label;

  @HiveField(1)
  String value;

  MagicAttribute({required this.label, required this.value});
}
