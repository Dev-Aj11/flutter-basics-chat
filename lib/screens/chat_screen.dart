import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final messageTextController = TextEditingController();
  String messageText;

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
    }
  }

/*
  void getMessages() async {
    // returns a future list of messages in _JsonQueryDocSnapshot format
    final messages = await _firestore.collection('messages').get();
    for (var message in messages.docs) {
      // unwrap _JsonQueryDocSnapshot into json
      print(message.data());
    }
  }
*/

  void messagesStream() async {
    // returns a stream of query snapshots
    // subscribe myself to listen to changes
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    print(loggedInUser.email);
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
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
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // database: messages > unique_key > {'text': <insert>, 'sender': <insert>}
                      _firestore.collection('messages').add(
                        {
                          'text': messageText,
                          'sender': loggedInUser.email,
                          'timestamp': FieldValue.serverTimestamp()
                        },
                      );
                      messageText = "";
                      messageTextController.clear();
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

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print(loggedInUser);
    return StreamBuilder<QuerySnapshot>(
      // stream to subscribe to
      // _firestore....snapshots(): Instance of '_MapStream<QuerySnapshot>'
      stream:
          _firestore.collection('messages').orderBy('timestamp').snapshots(),

      // builder will trigger when stream is updated with new event
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        /*
        snapshot: Instance of AsyncSnapshot<QuerySnapshot> 
          (AsyncSnapshot provided by Flutter; QuerySnapshot provided by Firebase)
        snapshot.data: Instance of _QuerySnapshot (collection)
        snapshot.data.docs: List<QueryDocumentSnapshot> (documents)
        */
        final messages = snapshot.data.docs.reversed;
        List<MessageBubble> messageWidgets = [];
        for (var message in messages) {
          final messageText = message['text'];
          final messageSender = message['sender'];
          final currentUser = loggedInUser.email;
          final messageBubbles = MessageBubble(messageSender, messageText,
              currentUser == messageSender ? true : false);
          messageWidgets.add(messageBubbles);
        }
        return Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(),
            children: messageWidgets,
            reverse: true,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String messageText, messageSender;
  final bool isMe;
  MessageBubble(this.messageSender, this.messageText, this.isMe);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            messageSender,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(
            height: 5,
          ),
          Material(
            borderRadius: BorderRadius.only(
              topLeft: isMe ? Radius.circular(30.0) : Radius.circular(0),
              topRight: isMe ? Radius.circular(0) : Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.grey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                '$messageText',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
