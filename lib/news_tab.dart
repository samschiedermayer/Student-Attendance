import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_attendance/news_item.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsTab extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection('news').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();
          return _buildNewsList(context, snapshot.data.documents);
        },
      ),
    );
  }

  Widget _buildNewsList(
      BuildContext context, List<DocumentSnapshot> snapshots) {
    if (snapshots.length == 0) {
      return Center(
        child: Text('Announcements Unavailable',
            style: new TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                shadows: <Shadow>[
                  Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 1.0,
                      color: Colors.black26),
                  Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 1.0,
                      color: Colors.black12)
                ])),
      );
    } else {
      return ListView(
        padding: EdgeInsets.all(8.0),
        children: snapshots
            .map((data) => _buildNewsItem(context, NewsItem.fromSnapshot(data)))
            .toList(),
      );
    }
  }

  //TODO FIX THE VISUALS FOR THIS WIDGET!!
  Widget _buildNewsItem(BuildContext context, NewsItem newsItem) {
    final String name = newsItem.name,
        imageUrl = newsItem.imageUrl,
        linkUrl = newsItem.linkUrl,
        content = newsItem.content;
    if (content != null) {
      return Padding(
        key: ValueKey(name),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(5.0),
            color: Theme.of(context).accentColor,
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Divider(
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 12.0),
                child: Text(
                  content,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (imageUrl != null && linkUrl != null) {
      return Padding(
        key: ValueKey(name),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: GestureDetector(
          onTap: () => _onImageTapped(linkUrl),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(5.0),
              color: Theme.of(context).accentColor,
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Divider(
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    child: Image.network(imageUrl),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(5.0),
                      color: Theme.of(context).accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else
      return Text('Error');
  }

  void _onImageTapped(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
