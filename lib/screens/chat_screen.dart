import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

final Firestore _store = Firestore.instance;
FirebaseUser loggedInUser;

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String text;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

//  void getMessage() async {
//    var messages = await _store.collection('message').getDocuments();
//    for (var message in messages.documents) {
//      print(message.data);
//    }
//  }
  void messagesStream() async {
    //_store.collection('message').snapshots() return streams of snapshots in the future (a.k.a Future<List<QuerySnapshot>>)
    //so we use await for loop where everything inside the for loop will handle one snapshot
    //meanwhile, await indicates that whenever a bunch of QuerySnapshots is coming(we subscribe to it), we handle the same.
    await for (var snapshot in _store.collection('message').snapshots()) {
      for (var message in snapshot.documents) print(message.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged: (value) {
                        text = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      _store
                          .collection('message')
                          .add({'text': text, 'sender': loggedInUser.email});
                      messageController.clear();
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _store.collection('message').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlue,
            ),
          );
        }
        List<MessageBubble> messageWidgets = [];
        final messages = snapshot.data.documents.reversed;
        for (var message in messages)
          messageWidgets.add(MessageBubble(
            sender: message.data['sender'],
            message: message.data['text'],
            isSelf: loggedInUser.email == message.data['sender'],
          ));
        return Expanded(
            child: ListView(reverse: true, children: messageWidgets));
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.message, this.isSelf});
  final String sender;
  final String message;
  final bool isSelf;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text('$sender',
              style: TextStyle(color: Colors.black54, fontSize: 12)),
          Material(
            color: isSelf ? Colors.lightBlue : Colors.white,
            elevation: 5.0,
            borderRadius: BorderRadius.only(
                topLeft: isSelf ? Radius.circular(30.0) : Radius.circular(0.0),
                topRight: isSelf ? Radius.circular(0.0) : Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                '$message',
                style: TextStyle(
                    color: isSelf ? Colors.white : Colors.black54,
                    fontSize: 15.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
