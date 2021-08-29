import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

User user;
String titleVal = "";

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key key}) : super(key: key);
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  var auth = FirebaseAuth.instance;
  @override
  void initState() {
    user = auth.currentUser;
    if (user != null) {
      setState(() {
        titleVal = user.email;
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Temas Geçmişi"),
      ),
      body: StreamBuilder<QuerySnapshot>(
          // <2> Pass `Stream<QuerySnapshot>` to stream
          stream: Firestore.instance.collection('ArsivGecmisi').orderBy("date",descending:true).snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            return ListView(
              children: snapshot.data.docs.where((element) => element["userId"] == user.uid).map((document) {
                return Card(
                  margin: EdgeInsets.all(10),
                  elevation: 20,
                  color: Colors.red[200],
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.coronavirus_rounded),
                      radius: 15,
                    ),
                    title: Text(DateFormat('yyyy-MM-dd – kk:mm')
                            .format(DateTime.parse(document["date"])) +
                        " tarihinde."),
                    subtitle: Text(document["meter"] +
                        " metre yakınınızda covid hastası vardı."),
                    trailing: Icon(Icons.history),
                  ),
                );
              }).toList(),
            );
          }),
    );
  }
}
