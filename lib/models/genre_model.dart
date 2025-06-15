import 'package:pocketbase/pocketbase.dart';

class GenreModel {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final IconInfo? icon;
  final DateTime created;
  final DateTime updated;

  GenreModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.icon,
    required this.created,
    required this.updated,
  });

  factory GenreModel.fromRecord(RecordModel record, {String? baseUrl}) {
    // Handle icon which is a file in PocketBase
    IconInfo? iconInfo;
    String? iconUrl;
    
    if (record.data['icon'] != null) {
      // Format for PocketBase file URLs: {baseUrl}/api/files/{collectionId}/{recordId}/{fileName}
      if (baseUrl != null) {
        iconUrl = '$baseUrl/api/files/${record.collectionId}/${record.id}/${record.data['icon']}';
      }
    }

    return GenreModel(
      id: record.id,
      name: record.data['name'] ?? '',
      description: record.data['description'],
      iconUrl: iconUrl,
      icon: iconInfo,
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
    );
  }
}

class IconInfo {
  final String filename;
  final String url;
  
  IconInfo({
    required this.filename,
    required this.url,
  });
}
