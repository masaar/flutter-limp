import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:union/union.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:rxdart/subjects.dart';
import 'package:crypto/crypto.dart';


import 'package:path/path.dart';
import 'package:async/async.dart';


class utils {
    static final Random _random = Random.secure();

    static String CreateCryptoRandomString([int length = 32]) {
        var values = List<int>.generate(length, (i) => _random.nextInt(256));

        return base64Url.encode(values);
    }
}

class SDKConfig {
   String  api;
  String anonToken;
  List<String> authAttrs;
  bool debug;
  num fileChunkSize;
  String authHashLevel ;

SDKConfig();
}

class QueryStep {
	String $search;
  num $sort;
	// $sort?: {
	// 	[attr: string]: 1 | -1;
	// };
  num $skip;
  num $limit;
  // var $extn = null? false : new List<String>();
  Union2< bool, List<String>> $extn  = false.asFirst();
	// $extn?: false | Array<string>;
  List<String> $attrs;
  List<Map> $group;
	// 	by: string;
	// 	count: number;
	// }>;
  Map $geo_near;
	// $geo_near?: {
	// 	val: [number, number];
	// 	attr: string;
	// 	dist: number
	// };
// 	[attr: string]: {
// 		$ne: any;
// 	} | {
// 		$eq: any;
// 	} | {
// 		$regex: string;
// 	} | {
// 		$gt: number | string;
// 	} | {
// 		$gte: number | string;
// 	} | {
// 		$lt: number | string;
// 	} | {
// 		$lte: number | string;
// 	} | {
// 		$bet: [number, number] | [string, string];
// 	} | {
// 		$all: Array<any>;
// 	} | {
// 		$in: Array<any>;
// 	} | {
// 		$attrs: Array<string>;
// 	} | {
// 		$skip: false | Array<string>;
// 	} | Query | string | { [attr: string]: 1 | -1; } | number | false | Array<string> | {
// 		val: [number, number];
      String attr;
      num dist;
// 		attr: string;
// 		dist: number;
// 	};
}

mixin Query implements List<dynamic> {}

class CallArgs {
  String call_id;
  String endpoint;
  String sid;
  String token;
  List<dynamic> query;
  dynamic doc;
}

class Res<T> {
	// dynamic args = {
	// 	call_id: string;
	// 	watch?: string;
	// 	// [DOC] Succeful call attrs
	// 	docs?: Array<T>;
	// 	count?: number;
	// 	total?: number;
	// 	groups?: any;
	// 	session?: Session;
	// 	// [DOC] Failed call attrs
	// 	code?: string;
	// }
// 	msg: string;
// 	status: number;
}

class Doc {
  String _id;
  Map args;
// 	_id: string;
// 	[key: string]: any;
}

class Session extends Doc {
  User user;
  String host_add;
  String user_agent;
  String timestamp;
  String expiry;
  String token;
}

class User extends Doc {
// 	name: { [key: string]: string };
String locale;
String create_time;
String login_time;
List<String> groups;
// 	privileges: { [key: string]: Array<string>; },
// 	status: 'active' | 'banned' | 'deleted' | 'disabled_password',
// 	attrs: {
// 		[key: string]: any;
// 	};
}

class WebsocketConnetion {
  String webURL;
  IOWebSocketChannel websocket;
  Stream myStream;
  
  WebsocketConnetion(this.webURL){
    this.websocket = IOWebSocketChannel.connect(this.webURL);
  }
  
  initConnection(){
    print('connection start initialisation....');
    
    
    myStream = this.websocket.stream.asBroadcastStream();
  }
 
}

class ApiService{

bool heartbeat = true;
// 	appActive: boolean = true;

bool appActive = true;
bool debug = false;

List<dynamic> authQueue = new List<dynamic>();
List<dynamic> noAuthQueue  = new List<dynamic>();

bool inited = false;
StreamController<bool> inited$ = new StreamController<bool>.broadcast();

bool authed = false;
StreamController<dynamic> authed$ = new StreamController<dynamic>.broadcast();

dynamic session;
Stream websocketStream;
WebsocketConnetion conn;
SharedPreferences cache ;
SDKConfig config = new SDKConfig();
StreamController<dynamic> subject = new StreamController<dynamic>.broadcast();

ApiService() {
  sharedPre();
  this.authed$.stream.listen(
    (data){
      // if(data != null) this.authed = true;
      print('authed values is $data');

      this.authQueue.forEach((item){
        
        dynamic apiCall = item;
        apiCall["token"] = session["token"];
          final claimSet = new JwtClaim(
          otherClaims: <String,dynamic>{...apiCall},
          maxAge: const Duration(minutes: 2)
          );
          String sJWT = issueJwtHS256(claimSet, apiCall['token']);
    
          this.conn.websocket.sink.add(jsonEncode({
            "token" : sJWT,
            "call_id" : apiCall['call_id'] }));
        });
        this.authQueue = [];
      },
      onError: (err){
        print('authed subscription error $err');
      },
      onDone: (){
        print('auth controll is done.');
      }
    );

    this.inited$.stream.listen(
      (data){
        print('inited values is $data');
        this.inited = data;
        if(data)this.heartBeat();
        else this.heartbeat = false;

        this.noAuthQueue.map((item){
          dynamic apiCall = item;

          apiCall["token"] = session["token"];

          final claimSet = new JwtClaim(
          otherClaims: <String,dynamic>{...apiCall},
          maxAge: const Duration(minutes: 2)
          );
          String sJWT = issueJwtHS256(claimSet, apiCall['token']);
    
          this.conn.websocket.sink.add(jsonEncode({
            "token" : sJWT,
            "call_id" : apiCall['call_id'] }));
        });
      },
      onError: (err){
        this.heartbeat = false;
        print('inited subscription error $err');
      },
      onDone: (){
        this.heartbeat = false;
        print('inited stream Controller is done.');
      }
    );

  }

  printLog(String log){
      print(log);
  }

  sharedPre() async{
    this.cache = await  SharedPreferences.getInstance();
  }
  void init(String api, String token, List<String> authattr,bool debug){

    this.config.api = api;
    this.config.anonToken = token;
    this.config.authAttrs = authattr;
    this.config.debug = debug;
    this.config.authHashLevel = '6.1';


    conn = new WebsocketConnetion(api);
    // conn.initConnection();
    this.websocketStream = this.conn.websocket.stream.asBroadcastStream();
    this.websocketStream.listen(
      (data){
        dynamic res = jsonDecode(data);
        print('message in response : ${res["msg"]}');

        if(res["args"]["code"] == "CORE_CONN_READY"){
          this.reset();
          this.config.anonToken = '__ANON_TOKEN_f00000000000000000000012';
          this.newcall('conn/verify',{});

        } else if( res["args"]["code"] == "CORE_CONN_OK"){
          print('connection is ready to use....');
          this.inited = true;
          this.inited$.add(true);

          try {
            this.checkAuth();
          } catch (e) {
            print(e);
          }
        } else if( res["args"]["code"] =="CORE_CONN_CLOSED"){
          this.reset();

        } else if(res["args"]["session"] != null){
          print(res["args"]["session"]["_id"]);
          print(res["args"]["session"]["token"]);

          if(res["args"]["session"]["_id"] == "f00000000000000000000012"){
            if (this.authed) {
							this.authed = false;
							this.session = null;
							this.authed$.add(false);
						}
						this.cache.remove('token');
						this.cache.remove('sid');
						print('Session is null');
          } else {
            this.cache.setString("sid", res["args"]["session"]["_id"]);
            this.cache.setString("token", res["args"]["session"]["token"]);
            this.authed = true;
            authed$.add(true);
            this.session = res["args"]["session"];
          }
        }
         subject.add(data);
      },
      onError: (err){
        print(err);
        subject.addError(err);
        this.reset();
      },
      onDone: (){
       this.reset();
        },
      cancelOnError:true
    );
  }

  void heartBeat() async{
    this.newcall('heart/beat', {});
      Future.delayed(Duration(seconds: 30),(){
        if(heartbeat) this.heartBeat();
      });
  }
  reset({bool forceInited = false}){
    // this.cache.clear();
			this.authed = false;
			if (this.session != null) {
				this.session = null;
				this.authed = false;
				this.authed$.add(false);
			}

			if (this.inited) {
				this.inited = false;
				this.inited$.add(false);
			}
  }

   void call(String endpoint, dynamic callArgs,[ bool awaitAuth = false]){
          
    dynamic apiCall = {
      'endpoint' : endpoint != null? endpoint : callArgs['endpoint'],
      'sid' : (this.cache.getString('sid') != null)? this.cache.getString('sid'): "f00000000000000000000012",
      'token' : (this.cache.getString('token') != null)? this.cache.getString('token') : this.config.anonToken,
      'query' : callArgs['query']!=null? callArgs['query'] : [] ,
      'doc' : callArgs['doc'] != null ? callArgs['doc'] : {},
      'call_id' : utils.CreateCryptoRandomString().substring(5,11).toLowerCase()
    };

    final subject = BehaviorSubject<bool>();
    Stream strm = subject.stream;

    if ((this.inited && awaitAuth && this.authed) || (this.inited && !awaitAuth) || endpoint == 'conn/verify') {
      // CombineLatestStream([strm], (combiner){
      //    final claimSet = new JwtClaim(
      //    otherClaims: <String,dynamic>{...apiCall},
      //    maxAge: const Duration(minutes: 2)
      //    );
      //    String sJWT = issueJwtHS256(claimSet, apiCall['token']);

      //   this.conn.websocket.sink.add(jsonEncode({
      //      "token" : sJWT,
      //      "call_id" : apiCall['call_id'] }));
      //    });
    } else {
      if(awaitAuth){
        Union2<dynamic , String> queue;
        queue = apiCall.asFirst();
        queue = apiCall["call_id"].asSecond();
        this.authQueue.add(queue);
      } else {
        Union2<dynamic , String> queue;
        queue = apiCall.asFirst();
        queue = apiCall["call_id"].asSecond();
        this.noAuthQueue.add(queue);
      }
    }
    // print('call args : ${apiCall}');  
    final claimSet = new JwtClaim(
      otherClaims: <String,dynamic>{...apiCall},
      maxAge: const Duration(minutes: 2)
      );
      String sJWT = issueJwtHS256(claimSet, apiCall['token']);
      // print('jwt token ${sJWT}');
      this.conn.websocket.sink.add(jsonEncode({
        "token" : sJWT,
        "call_id" : apiCall['call_id'] }));
  }

StreamController<dynamic> newcall(String endpoint, dynamic callArgs,[ bool awaitAuth = false]) {
    print('start calling new call.. ');
    dynamic apiCall = {
      'endpoint' : endpoint != null? endpoint : callArgs['endpoint'],
      'sid' :  (this.authed)? this.cache.getString('sid'): "f00000000000000000000012",
      'token' : (this.authed)? this.cache.getString('token') : this.config.anonToken,
      'query' : callArgs['query']!=null? callArgs['query'] : [] ,
      'doc' : callArgs['doc'] != null ? callArgs['doc'] : {},
      'call_id' : utils.CreateCryptoRandomString().substring(5,11).toLowerCase()
    };
    print(apiCall);


    //// file upload////
    List<Stream> fileUploads = [];
    List<File> files;


    BehaviorSubject<dynamic> start = new BehaviorSubject<dynamic>();
    fileUploads.add(start.stream);

    if( callArgs['doc'] != null)
      callArgs['doc'].forEach((key,value) {
      if(value[0].runtimeType.toString() == '_File'){

        print(value);
        files =  value;
        callArgs['doc'][key] = [];

        apiCall['doc'][key] = [];


        files.forEach((file){
        //  BehaviorSubject<dynamic> upload = new BehaviorSubject<dynamic>();
          // fileUploads.add(upload.stream);
          // apiCall['doc'][key].add(file.path.split('/')[file.path.split('/').length -1]);
          Stream upload = this.uploadFile(file, apiCall, key).asStream().asBroadcastStream();
          fileUploads.add(upload);
          upload.listen(
            (res){
              apiCall['doc'][key].add( {'__file' : res.data['args']['docs'][0]['_id']} );
            },onDone: (){}
          );
          
          // apiCall['doc'][key].add(file.path.split('/')[file.path.split('/').length -1]);
          
          // print('start uploading .......$apiCall');
          // var url =this.config.api.replaceFirst('ws', 'http').replaceAll('/ws', '') + '/file/create' ;

          // var dio = Dio();
          // dio.interceptors.add(LogInterceptor(responseBody: true));
          
          // FormData formData = new FormData.fromMap({
          //   "__module" : apiCall['endpoint'].split('/')[0],     
					// 	"__attr" : key,    
					// 	"name" : file.path.split('/')[file.path.split('/').length -1],
					// 	"type" : 'image/jpeg', 
					// 	"lastModified" : (new DateTime.now().millisecondsSinceEpoch / 1000).toString().split('.')[0],  						
          //   "file": await MultipartFile.fromFile(file.path,filename: file.path.split('/')[file.path.split('/').length -1]), ///nother exception was thrown: type 'String' is not a subtype of type 'File' of 'value'
          // });


          // var response;
          // try {
          //   response= await dio.post(url, data: formData, 
          //   options: Options(
          //    headers: {
          //     'Content-Type': 'multipart/form-data',
					// 		'X-Auth-Bearer': apiCall['sid'],
					// 		'X-Auth-Token': apiCall['token'],
					// 		'X-Auth-App': 'this.config.appId',
          //   }
          //  ),
          //  );
          // } on DioError catch (e) {
          //   if(e.response != null){
          //     print(e.response.data);
          //   } else print(e.message);
          // }

          // // callArgs.doc[attr][i] = { __file: res.args.docs[0]._id };
          // apiCall['doc'][key][0] = {'__file' : response.data['args']['docs'][0]['_id']};
          
          // upload.add(response.data);



          // fileUploads.add(this.uploadFile(file, apiCall, apiCall['doc'][key]).asStream());
          // print('file upload results.... ${apiCall}');   
          
        });

      }
    });

    if(this.inited && awaitAuth && this.authed) print('first...');

    if(this.inited && !awaitAuth) print('second...');

    if(endpoint == 'conn/verify') print('third...');
    start.add('event');

    if ((this.inited && awaitAuth && this.authed) || (this.inited && !awaitAuth) || endpoint == 'conn/verify') {
      print('pre combineLatest...$apiCall');
      CombineLatestStream(fileUploads, (combiner){

        print('new call combine latest part...${apiCall}  $combiner');
         final claimSet = new JwtClaim(
         otherClaims: <String,dynamic>{...apiCall},
         maxAge: const Duration(minutes: 2)
         );
         String sJWT = issueJwtHS256(claimSet, apiCall['token']);
         // print('jwt token ${sJWT}');
        this.conn.websocket.sink.add(jsonEncode({
           "token" : sJWT,
           "call_id" : apiCall['call_id'] 
           }));
      }).listen(null);
    } else {
      if(awaitAuth){
        this.authQueue.add(apiCall);
      } else {
        this.noAuthQueue.add(apiCall);
      }
    }

    StreamController<dynamic> call = new StreamController<dynamic>();

    StreamSubscription subscription;
     subscription = this.subject.stream.listen(
      (data){
        dynamic res = jsonDecode(data);
        print('call stream receive data... ${res["args"]["call_id"]}');
        
        if(res["args"]["call_id"] == apiCall['call_id']) {
          call.add(res);
          call.close();
          subscription.cancel();
          } else {print('this is wrong data....${res["args"]["call_id"]}  ${apiCall['call_id']}');}
      },
      onError: (err){
          call.addError(err);
      },
      onDone: (){
        call.close();
      },
      cancelOnError: true
    ) ;

    return call;
  }

  Future<dynamic> uploadFile(File _image, dynamic callArgs, String attr ) async {

          var url =this.config.api.replaceFirst('ws', 'http').replaceAll('/ws', '') + '/file/create' ;

          var dio = Dio();
          dio.interceptors.add(LogInterceptor(responseBody: true));
          
          FormData formData = new FormData.fromMap({
            "__module" : callArgs['endpoint'].split('/')[0],     
						"__attr" : attr,    
						"name" : _image.path.split('/')[_image.path.split('/').length -1],
						"type" : 'image/jpeg', 
						"lastModified" : (new DateTime.now().millisecondsSinceEpoch / 1000).toString().split('.')[0],  						
            "file": await MultipartFile.fromFile(_image.path,filename: _image.path.split('/')[_image.path.split('/').length -1]), ///nother exception was thrown: type 'String' is not a subtype of type 'File' of 'value'
          });


          var response;
          // try {
            response=  await dio.post(url, data: formData, 
            options: Options(
             headers: {
              'Content-Type': 'multipart/form-data',
							'X-Auth-Bearer': callArgs['sid'],
							'X-Auth-Token': callArgs['token'],
							'X-Auth-App': 'this.config.appId',
            }
           ),
           );
          // } on DioError catch (e) {
          //   if(e.response != null){
          //     print(e.response.data);
          //   } else print(e.message);
          // }
        print('file upload results.... $response');

        return response;
  }

  void close(){
    this.newcall('conn/close',{
      'query' : [],
      'doc' : {}
    });
    // this.cache.clear();
  }

void deleteWatch({String watch}){
		var call = this.call('watch/delete', { "query": [{ watch: watch }] });
		// call.subscribe({
		// 	error: (err) => { this.log('error', 'deleteWatch call err:', err); }
		// });
	}

  reauth(String sid, String token) {
		// let oHeader = { alg: 'HS256', typ: 'JWT' };
		// let sHeader = JSON.stringify(oHeader);
		// let sPayload = JSON.stringify({ token: token });
		// let sJWT = JWS.sign('HS256', sHeader, sPayload, { utf8: token });
      // final claimSet = new JwtClaim(
      //   otherClaims: <String,dynamic>{},
      //   maxAge: const Duration(minutes: 2)
      // );
      // String token = issueJwtHS256(claimSet, this.config.anonToken);
		// let call: Observable<Res<Doc>> = this.call('session/reauth', {
		// 	sid: 'f00000000000000000000012',
		// 	token: this.config.anonToken,
		// 	query: [
		// 		{ _id: sid || 'f00000000000000000000012', hash: sJWT.split('.')[1] }
		// 	]
		// });
      print('start reauth ....');
      this.newcall('session/reauth',{
        "sid" : 'f00000000000000000000012',
        "token" : this.config.anonToken,
        "query" : [{ "_id": sid , "token": token }]
		// 	]]
      }).stream.listen(
        (res){
          print('reauth successfull....$res');
        }, onError: (err){
          this.cache.remove('sid');
          this.cache.remove('token');
          print(err);
        }, onDone: (){
          print('reauth done...');
        }
      );
	}


StreamController<dynamic> auth(String authVar,String authVal,String password){
		// if (this.config.authAttrs.indexOf(authVar) == -1) {
		// 	throw new Error(`Unkown authVar '${authVar}'. Accepted authAttrs: '${this.config.authAttrs.join(', ')}'`);
		// }
    StreamController<dynamic> call = new StreamController<dynamic>();

		dynamic doc= { "hash": this.generateAuthHash(authVar, authVal, password) };
		doc[authVar] = authVal;
    // doc = jsonEncode(doc);
    print('doc of auth.... ${doc}');

		this.newcall('session/auth',{
      "doc": doc //need to chage with new hashes
      }).stream.listen(
        (res){
          call.add(res);
          call.close();
        }, onError: (err){
          call.addError(err);
          call.close();
        },
        onDone: (){
          call.close();
        }
      );
      return call;
	
  } 
  
  // generateAuthHash(authVar: string, authVal: string, password: string): string {

	// 	if (this.config.authAttrs.indexOf(authVar) == -1 && authVar != 'token') {
	// 		throw new Error(`Unkown authVar '${authVar}'. Accepted authAttrs: '${this.config.authAttrs.join(', ')}, token'`)
	// 	}

	// 	if (this.config.authHashLevel != '6.1') {
	// 		let oHeader = { alg: 'HS256', typ: 'JWT' };
	// 		let sHeader = JSON.stringify(oHeader);
	// 		let hashObj = [authVar, authVal, password];
	// 		if (this.config.authHashLevel == '5.6') {
	// 			hashObj.push(this.config.anonToken);
	// 		}
	// 		let sPayload = JSON.stringify({ hash: hashObj });
	// 		let sJWT = JWS.sign('HS256', sHeader, sPayload, { utf8: password });
	// 		return sJWT.split('.')[1];
	// 	} else {
	// 		if (!password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.{8,})/)  ) {
	// 			throw new Error('Password should be 8 chars, contains one lower-case char, one upper-case char, one number at least.');
	// 		}
	// 		return `${authVar}${authVal}${password}${this.config.anonToken}`;
	// 	}
	// }

  String generateAuthHash( String authVar,String authVal,String password) {
    
    // var passHash = PassCrypt('SHA-512/HMAC/PBKDF2');
    // var keycryp= passHash.hashPass("\$%^789qwe:+971501234567", "phone:+971501234567:\$%^789qwe:__ANON_TOKEN_f00000000000000000000012",64);

    // print( 'new cryto key is ${keycryp}');  
  

    if(config.authHashLevel != '6.1'){
        List<String> hashObj = [authVar, authVal, password, this.config.anonToken]; // one thing
		    // if (this.config.authHashLevel == 5.6) {
		    // 	hashObj.add(this.config.anonToken);
		    // }
		    final sPayload = {
          "hash" : hashObj
        };    // second thing after that we generte 
		    // var sJWT = JWS.sign('HS256', sHeader, sPayload, { utf8: password });
        final key = this.config.anonToken;
        final claimSet = new JwtClaim(
          expiry: new DateTime.now(),
          issuedAt: null,
          otherClaims: <String,dynamic>{...sPayload},
          );
          String sJWT = issueJwtHS256(claimSet, key);
		    return sJWT.split('.')[1];
    } else { 
      // if (!password.contains(new RegExp(r'/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.{8,})/'))) {
			// 	throw("Password should be 8 chars, contains one lower-case char, one upper-case char, one number at least.");
			// }
			// return `${authVar}${authVal}${password}${this.config.anonToken}`;
      return authVar+ authVal+password+this.config.anonToken;
    }
		
	}


void signOut(){
    this.call('session/signout', {
			"query": [
				{ "_id": this.cache.get('sid') }
			]
		});
    this.cache.clear();
    this.authed = false;
    this.authed$.add(false);
}

void checkAuth() {
    // need some work here for hashes.
    print("check authrisation .....${this.cache.get('token')}  ${this.cache.get('sid')}");
  	if (this.cache.get('token') == null || this.cache.get('sid') == null) throw('re auth error...');
  	this.reauth(this.cache.get('sid'), this.cache.get('token'));
  }
}