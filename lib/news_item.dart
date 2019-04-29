import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

class NewsItem {
  String name, imageUrl, linkUrl, content;
  DocumentReference reference;

  NewsItem({@required this.name, this.imageUrl, this.linkUrl, this.content});

  NewsItem.fromMap(Map<String, dynamic> map, {this.reference})
      : name = map['name'],
        imageUrl = map['imageUrl'],
        linkUrl = map['linkUrl'],
        content = map['content'];

  NewsItem.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  Map<String, dynamic> toMap() {
    return {
      'name' : name,
      'imageUrl' : imageUrl,
      'linkUrl' : linkUrl,
      'content' : content
    };
  }
}