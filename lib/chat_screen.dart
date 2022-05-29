import 'dart:io';

import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<User?> _getUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      final GoogleSignInAuthentication? googleSignInAuthentication =
          await googleSignInAccount?.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication!.idToken,
          accessToken: googleSignInAuthentication.accessToken);

      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = authResult.user;

      return user;
    } catch (error) {
      return null;
    }
    return null;
  }

  void _sendMessage({String? text, File? imgFile}) async {
    final User? user = await _getUser();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível fazer o login, Tente novamente'),
        backgroundColor: Colors.red,
      ));
    }

    Map<String, dynamic> data = {
      'uid': user!.uid,
      'senderName': user.displayName,
      'senderPhotoUrl': user.photoURL,
      'time': Timestamp.now()
    };

    if (imgFile != null) {
      UploadTask task = FirebaseStorage.instance
          .ref()
          .child(user.uid + DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(imgFile);

      setState(() {
        _isLoading = true;
      });

      String url = await (await task).ref.getDownloadURL();
      data['imgUrl'] = url;

      setState(() {
        _isLoading = false;
      });
    }
    if (text != null) data['text'] = text;
    FirebaseFirestore.instance.collection('messages').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_currentUser != null
            ? 'Olá, ${_currentUser!.displayName}'
            : 'Chat App'),
        elevation: 0,
        actions: [
          _currentUser != null
              ? IconButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Você saiu com Sucesso'),),);
                  },
                  icon: const Icon(Icons.exit_to_app))
              : Container()
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('messages').orderBy('time').snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> documents =
                        snapshot.data!.docs.reversed.toList();
                    return ListView.builder(
                      itemCount: documents.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        return ChatMessage(
                            documents[index].data() as Map<String, dynamic>,
                            (documents[index].data() as Map)['uid'] == _currentUser?.uid);
                      },
                    );
                }
              },
            ),
          ),
          _isLoading ? const LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
