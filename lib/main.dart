import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterapp/flutter-limp.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:rxdart/subjects.dart';
import 'dart:async';
import 'package:web_socket_channel/status.dart' as status;

void main() => runApp(MaterialApp(
  home: new MyHomePage( title: 'Flutter LIMP SDK',
    // channel: new IOWebSocketChannel.connect('wss://qartapi.azurewebsites.net/ws'),
  )
));

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  String url =  "wss://limp-sample-app.azurewebsites.net/ws";
  String token = "__ANON_TOKEN_f00000000000000000000012";
  String connectionStatus = 'none';

  String result = 'results';

  ApiService api = new ApiService();

  
  Stream subStream;
  StreamSubscription subscription ; 
@override
  void initState() {
    super.initState();
  }

  void subjectCheck(){
    subStream = api.subject.stream;
    
    subscription = subStream.listen(
      (data){
        print('subcription data ${data}');
      }
    );
  }

  websocketconnections(){
    this.api.init(url,token, ['phone','email'],false);
    
    this.api.websocketStream.listen(
     (data){
       setState(() {
         this.connectionStatus = 'connected';
       });
       
      // print('data received :');
     },
     onError: (err){
      //  print('Error server : ${err}');
       setState(() {
         this.connectionStatus = 'disconnected on error';
       });
       
     },
     onDone: (){
      //  randomCalls();
       setState(() {
          this.connectionStatus =  'close connection on done';
       });
      
      //  print('done');
       Future.delayed(Duration(seconds: 5),(){
         websocketconnections();
       });
     },
     cancelOnError: false
    );
    setState(() {
      this.connectionStatus = 'Connection initlizing.....';
    });
  }

  File _image;
  Future pickimage() async {
  var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
    _image = image;
    });
  }

  closeConnection(){
  this.api.close();
}
  login(){
  this.api.auth("email", "ADMIN@LIMP.MASAAR.COM", "__ADMINx0");
}
  logout(){
    this.api.signOut();
}
  fileUpload(){
    dynamic doc = {
      'name': {
          'ar_AE': 'ali',
          'en_AE':'ali'
      },
      'jobtitle': {
           'ar_AE': 'ali',
          'en_AE':'ali'
      },
      'bio': {
          'ar_AE': 'ali',
          'en_AE':'ali'
      },
      'photo': [this._image]  
    };

    
    List<File> abcd =  [this._image, this._image, this._image] ;
    // abcd.forEach((element){ print('element.path');});
    // doc.forEach((key,value){
    //     print(value);
    //     print(value.runtimeType);
    //     // if(value[0].runtimeType.toString() == 'String'){
    //     //   List<String> abcd = value;
    //     //   print('list value $abcd');
    //     // abcd.forEach((element) => print(element));
    //   // }  
    // });

    
    CombineLatestStream(
      [
        Stream.fromIterable(['a']),
        Stream.fromIterable(['b']),
        Stream.fromIterable(['C', 'D'])
      ],
      (values) => values.last
    )
    .listen(print);

    // this.api.newcall('staff/create', {'doc' : doc}).stream.listen(
    //   (res){
    //       print(res);
    //   }, onError: (err){
    //     print(err);
    //   }, onDone: (){
    //     print('upload call complete');
    //   }
    // );
  }
  void readCall() {

    Stream stream = this.api.newcall('call/read', {}, true).stream;
    StreamSubscription<dynamic> subscription = stream.listen(
      (res){
          print('new call result: ${res}');
          setState(() {
            this.result = res.toString();
          });
      },
      onError: (err){
        print(err);
      },
      onDone: (){
        print('new call done..');
      }
    );
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
        return Scaffold(
          appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: Text(widget.title),
          ),
          body: SingleChildScrollView(
                      child: Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: Column(
                // Column is also a layout widget. It takes a list of children and
                // arranges them vertically. By default, it sizes itself to fit its
                // children horizontally, and tries to be as tall as its parent.
                //
                // Invoke "debug painting" (press "p" in the console, choose the
                // "Toggle Debug Paint" action from the Flutter Inspector in Android
                // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
                // to see the wireframe for each widget.
                //
                // Column has various properties to control how it sizes itself and
                // how it positions its children. Here we use mainAxisAlignment to
                // center the children vertically; the main axis here is the vertical
                // axis because Columns are vertical (the cross axis would be
                // horizontal).
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(url),
                  Text(token),
                  Row( 
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                    RaisedButton(
                      child: Text('Connect'),
                      onPressed: (){
                      websocketconnections();
                    }),
                    Container(
                      width: 10,
                    ),
                    RaisedButton(
                      child : Text('Disconnect'),
                      onPressed: closeConnection
                    )
                  ],),
                   Row( 
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                    RaisedButton(
                      child: Text('Login'),
                      onPressed: login),
                    Container(
                      width: 10,
                    ),
                    RaisedButton(
                      child : Text('logout'),
                      onPressed: logout
                    )
                  ],
                  ),
                   Row( 
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                    RaisedButton(
                      child: Text('select File'),
                      onPressed: pickimage ),
                    Container(
                      width: 10,
                    ),
                    RaisedButton(
                      child : Text('Upload'),
                      onPressed: fileUpload
                    )
                  ],
                  ),
                  Text(
                    'Connection Status: $connectionStatus',                  
                  ), Text (
                    'login Status : ${api.authed}',
              ),  Text(result)
                
            ],
        ),
      ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: readCall,
        tooltip: 'Call',
        child: Icon(Icons.file_upload),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
