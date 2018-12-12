import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/image.dart'; // ignore: implementation_imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';


void main() async {
  //Firestore.instance.collection('mensagens').document('msg5').setData({'from':'joaquim', 'texto':'teste2'});

//  DocumentSnapshot snapshot = await Firestore.instance.collection('mensagens').document('msg2').get();
//  print(snapshot.data);
//  QuerySnapshot snapshot = await Firestore.instance.collection('mensagens').getDocuments();
//  for(DocumentSnapshot doc in snapshot.documents){
//    print(doc.data) ;
//  }
//print(snapshot.documents);

//  Firestore.instance.collection('mensagens').snapshots().listen((snapshot){
//    for(DocumentSnapshot doc in snapshot.documents) {
//      print(doc.data);
//    }
//  });

  runApp(MyApp());
}

final ThemeData kIOSTheme = ThemeData(
    primarySwatch: Colors.orange[500],
    primaryColor: Colors.lightBlue,
    primaryColorBrightness: Brightness.light);

final ThemeData kDefaultTheme = ThemeData(
  primarySwatch: Colors.blueGrey,
  accentColor: Colors.blueGrey,
);

final googleSignIn = GoogleSignIn();
final auth = FirebaseAuth.instance;

Future <Null>  _ensureLoggedIn() async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null)
    user = await googleSignIn.signInSilently();
  if (user == null) user = await googleSignIn.signIn();
  if (await auth.currentUser() == null) {
    GoogleSignInAuthentication credentials =
    await googleSignIn.currentUser.authentication;
    await auth.signInWithGoogle(
        idToken: credentials.idToken,
        accessToken: credentials.accessToken);
  }
}





_handleSubmitted(String text) async {
  await _ensureLoggedIn();
  _sendMessage(text: text);
}

void _sendMessage ({String text, String imgUrl}){
  Firestore.instance.collection('mensagens').add(
      {
        'text': text,
        'imgUrl': imgUrl,
        'senderName': googleSignIn.currentUser.displayName,
        'sendrFhotoUrl': googleSignIn.currentUser.photoUrl
      }
  );
}





class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Online',
      debugShowCheckedModeBanner: false,
      theme: Theme.of(context).platform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefaultTheme,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chat App'),
          centerTitle: true,
          elevation:
          Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder(
                  stream: Firestore.instance.collection('mensagens').snapshots(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState){
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      default:
                        return ListView.builder(
                            reverse: true,
                            itemCount: snapshot.data.documents.length,
                            itemBuilder: (context, index) {
                              List r = snapshot.data.documents.reversed.toList();
                              return ChatMessage( r [index].data);
                            }
                        );
                    }
                  }
              ),
            ),
            Divider(
              height: 1.0,
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: TextComposer(),
            )
          ],
        ),
      ),
    );
  }
}

class TextComposer extends StatefulWidget {
  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  final _textController = TextEditingController();
  bool _isComposing = false;
  void _reset(){
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: Theme.of(context).platform == TargetPlatform.iOS
            ? BoxDecoration(
          // ignore: undefined_getter
            border: Border(top: BorderSide(color: Colors.grey)))
            : null,
        child: Row(
          children: <Widget>[
            Container(
              child:
              IconButton(icon: Icon(Icons.photo_camera),
                  onPressed: () async {
                  await _ensureLoggedIn();
                  File imgFile = await ImagePicker.pickImage(source: ImageSource.camera);
                  if (imgFile == null) return;
                  StorageUploadTask task = FirebaseStorage.instance.ref().
                  child(googleSignIn.currentUser.id.toString() + DateTime.now().millisecondsSinceEpoch.toString()).putFile(imgFile);
                  _sendMessage(imgUrl: (await task.future).downloadUrl.toString());

                  //
                  }),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration:
                InputDecoration.collapsed(hintText: 'Enviar uma mensagem'),
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: (text){
                  _handleSubmitted(text);
                  _reset();
                },
              ),
            ),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? CupertinoButton(
                  child: Text('Enviar'),
                  onPressed: _isComposing ? () { _handleSubmitted(_textController.text);
                  _reset();
                  }: null,
                )
                    : IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isComposing ? () { _handleSubmitted(_textController.text);
                  _reset();
                  } : null,
                ))
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {

  //final ImageProvider backgroundImage;

  final Map<String, dynamic> data;
  ChatMessage(this.data);



  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage('https://image.shutterstock.com/image-vector/dog-icon-450w-311365823.jpg'),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data['senderName'],
                  style: Theme.of(context).textTheme.subhead,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: data['imgUrl'] != null?
                  Image.network(data ['imgUrl'], width: 250.00,) :
                  Text(data ['text'])

                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
