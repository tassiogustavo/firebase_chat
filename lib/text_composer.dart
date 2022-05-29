import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  const TextComposer(this.sendMessage, {Key? key}) : super(key: key);

  final Function({String text, File imgFile}) sendMessage;

  @override
  State<TextComposer> createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  final TextEditingController _controller = TextEditingController();

  bool _isComposing = false;

  void _reset() {
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () async{
              XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
              final File imgFile = File(image!.path);
              if(imgFile == null) return;
              widget.sendMessage(imgFile: imgFile);
            },
            icon: const Icon(Icons.photo_camera),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (text) {
                setState(() {
                  _isComposing = text.isNotEmpty;
                });
              },
              onSubmitted: (text) {
                widget.sendMessage(text: text);
                _reset();
              },
              decoration: const InputDecoration.collapsed(
                  hintText: 'Enviar uma Mensagem'),
            ),
          ),
          IconButton(
            onPressed: _isComposing
                ? () {
                    widget.sendMessage(text: _controller.text);
                    _reset();
                  }
                : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
