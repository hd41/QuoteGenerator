import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
           home: RandomWords(),
           routes: <String, WidgetBuilder>{
             '/a': (BuildContext context) => AnotherIntent(),
           },
    );
  }
}

class RandomWordsState extends State<RandomWords>{

  final _suggestions  = <WordPair>[];
  final Set<WordPair> _saved = Set<WordPair>(); // Added for saved item
  final _biggerFont = const TextStyle(fontSize: 18.0);

  Widget _buildRow(WordPair pair) {
    final bool alreadySaved = _saved.contains(pair);

    return ListTile(
      title: Text(
      pair.asPascalCase,
      style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: (){
        setState(() {
          if(alreadySaved){
            _saved.remove(pair);
          }
          else{
            _saved.add(pair);
          }
        });
      }, // end of onTap
      onLongPress: (){
        Navigator.of(context).pushNamed('/a',
            arguments: ArgumentDict('You have pressed option: ', pair.asPascalCase
            ));
      },
    );
  } // end of BuildRow

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: /*1*/ (context, i) {
      if (i.isOdd) return Divider(); /*2*/

      final index = i ~/ 2; /*3*/
      if (index >= _suggestions.length) {
      _suggestions.addAll(generateWordPairs().take(10)); /*4*/
      }
      return _buildRow(_suggestions[index]);
    });
  }// end of _buildSuggestions

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          final Iterable<ListTile> tiles = _saved.map(
                (WordPair pair) {
              return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
              );
            },
          );
          final List<Widget> divided = ListTile
              .divideTiles(
            context: context,
            tiles: tiles,
          )
              .toList();

          return Scaffold(         // Add 6 lines from here...
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );                       // ... to here.
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Startup Name Generator'),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.list), onPressed: _pushSaved)
        ],
      ),
      body: _buildSuggestions(),
    );
  }

}

class RandomWords extends StatefulWidget{

  @override
  State<StatefulWidget> createState() {
    return RandomWordsState();
  }

}

class AnotherIntent extends StatelessWidget {

  final textStyle = const TextStyle(fontSize: 18.0, fontFamily: 'Times New Roman');
  final textStyle1 = const TextStyle(fontSize: 24.0, fontFamily: 'Old Sans', color: Colors.deepOrangeAccent);

  @override
  Widget build(BuildContext context) {

    final ArgumentDict args = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text('Random Quote Generator'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Image.asset('image/lake.jpg'),

            Container(
              margin: EdgeInsets.all(20.0),
              padding: EdgeInsets.all(10.0),
              child: Row(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text(args.title, style: textStyle),
                      Text(args.value, style: textStyle1),
                    ],
                  ),
                  FavoriteWidget(),
                ],
              ),
            ),
            Text("Quotes", style: TextStyle(fontSize: 28.0)),
            FunFactWidget(),
          ],
        )

      ),
    );
  }

}

class ArgumentDict{
  final String title;
  final String value;

  ArgumentDict(this.title, this.value);
}


class FavoriteWidget extends StatefulWidget{

  @override
  _FavoriteWidgetState createState () => _FavoriteWidgetState();

}

class _FavoriteWidgetState extends State<FavoriteWidget>{

  bool _isFavorited = true;
  int _favoriteCount = 41;

  void _toggleFavorite() {
    setState(() {
      if (_isFavorited) {
        _favoriteCount -= 1;
        _isFavorited = false;
      } else {
        _favoriteCount += 1;
        _isFavorited = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(0),
          child: IconButton(
            icon: (_isFavorited ? Icon(Icons.star) : Icon(Icons.star_border)),
            color: Colors.red[500],
            onPressed: _toggleFavorite,
          ), // IconButton
        ), // Container
        SizedBox(
          width: 18,
          child: Container(
            child: Text('$_favoriteCount'),
          ),
        ),
      ],
    );

  }

}

class FunFactWidget extends StatefulWidget{

  final Future<Post> post;

  FunFactWidget({Key key, this.post}) : super(key: key);

  @override
  _FunFactState createState() => _FunFactState();

}

class _FunFactState extends State<FunFactWidget> {
  Future<Post> post;
  final _biggerFont = const TextStyle(fontSize: 22.0, color: Colors.blue);

  @override
  void initState() {
    super.initState();
    post = fetchPost();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: FutureBuilder<Post>(
            future: post,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data.quoteText, style: _biggerFont);
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }

              // By default, show a loading spinner.
              return CircularProgressIndicator();
            },
          ),
      ),
    );
  }
}

Future<Post> fetchPost() async {
  final response = await http.get('https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=json&json=?');

  if (response.statusCode == 200) {
    // If server returns an OK response, parse the JSON.
    return Post.fromJson(json.decode(response.body));
  } else {
    // If that response was not OK, throw an error.
    throw Exception('Failed to load post');
  }
}

class Post {
  final String quoteText;
  final String quoteAuthor;
  final String senderName;
  final String senderLink;
  final String quoteLink;

  Post({this.quoteText, this.quoteAuthor, this.senderName, this.senderLink, this.quoteLink});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      quoteText: json['quoteText'],
      quoteAuthor: json['quoteAuthor'],
      senderName: json['senderName'],
      senderLink: json['senderLink'],
      quoteLink: json['quoteLink']
    );
  }
}


