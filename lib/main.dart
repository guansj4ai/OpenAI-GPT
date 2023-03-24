import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAI Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'OpenAI Chat App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with AutomaticKeepAliveClientMixin<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  List<Map<String, String>> _messages = [];

  Future<Map<String, String>> _getOpenAIResponse(String message) async {
    print('Sending request with message: $message');

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer openkey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user", "content": "$message"}],
        "temperature": 0.7
      }),
    );
    print('Response received: ${utf8.decode(response.bodyBytes)}');
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final responseText =
          jsonResponse['choices'][0]['message']['content'].toString().trim();
      setState(() {
        _messages.insert(0, {'role': 'Boot', 'content': responseText});
      });
      return {'role': 'Boot', 'content': responseText};
    } else {
      if (response.statusCode != 200) {
        final error = 'Failed to load response with status code: ${response.statusCode}';
        print(error);
        print(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.insert(0, {'role': 'Boot', 'content': error});
        });
      }
    }
    return {'role': 'Boot', 'content': ''};
  }

  void _handleSubmitted(String text) async {
    _textController.clear();
    setState(() {
      _messages.insert(0, {'role': 'User', 'content': text});
    });

    final response = await _getOpenAIResponse(text);

    // setState(() {
    //   _messages.insert(0, response);
    // });
  }

  Widget _buildTextComposer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,              
              decoration: InputDecoration.collapsed(
                hintText: '继续聊天...',
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantMessage(String? text) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(child: Text('A')),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Boot', style: Theme.of(context).textTheme.subtitle1!),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: Text(text!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String? text) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text('User', style: Theme.of(context).textTheme.subtitle1!),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: Text(text!),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 16.0),
            child: CircleAvatar(child: Text('U')),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(8.0),
              itemBuilder: (_, int index) => _messages[index]['role'] == 'Boot'
                  ? _buildAssistantMessage(_messages[index]['content'])
                  : _buildUserMessage(_messages[index]['content']),
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }
}
