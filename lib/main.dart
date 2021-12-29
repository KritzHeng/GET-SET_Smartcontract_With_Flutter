import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String scoreContract;

  //get address from contract address
  final EthereumAddress contractAddress = EthereumAddress.fromHex('');
  //get abi from contract address
  final abi ='[ { "constant": false, "inputs": [ { "name": "_score", "type": "uint256" } ], "name": "set", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "score", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "stateMutability": "view", "type": "function" } ]';


  String rpcUrl = '';
  String wsUrl = '';


  @override
  void initState() {
    //TODO: implement initState
    super.initState();
    generateMnemonic();
  }


  void getScore() async{
    final contract = DeployedContract(ContractAbi.fromJson(abi.toString(), 'setScore'),contractAddress);

    final setScore = contract.function('score');
    final client = Web3Client(rpcUrl, Client(), socketConnector: (){
      return IOWebSocketChannel.connect(wsUrl).cast<String>();

    });
    try{
    final score = await client.call(contract:contract, function: setScore, params:[]);
    final get = EtherAmount.inWei(score.first as BigInt);
    print('this is score in contract ${get}');
    setState(() {
      scoreContract = get.getInWei.toString();

    });

    }catch(e){

    }

  }

  void setScore(String privateKey) async {
    final contract = DeployedContract(
        ContractAbi.fromJson(abi.toString(), 'setScore'), contractAddress);

    final set = contract.function('set');
    final client = Web3Client(rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(wsUrl).cast<String>();
    });
    final credentials = await client.credentialsFromPrivateKey(privateKey);
    final ownerAddress = await credentials.extractAddress();

    try {
      final transaction = await client.sendTransaction(
          credentials,
          Transaction.callContract(
            from: ownerAddress,
            contract: contract,
            maxGas: 50000,
            gasPrice: EtherAmount.inWei(BigInt.from(10 * 1e9)),
            function: set,
            parameters: [BigInt.from(15)],
          ),
          chainId: null,
          fetchChainIdFromNetworkId: true
      );
      print(transaction);
    }
    catch(e){
      print("something wrong.");
    }

  }


  void generateMnemonic() async{

    // var mnemonic = bip39.generateMnemonic();
    // print("mnemonuic: "+mnemonic);

    // var seed = bip39.mnemonicToSeedHex(mnemonic);
    var seed = bip39.mnemonicToSeedHex('a');
    final root = bip32.BIP32.fromSeed((HEX.decode(seed)));
    
    print(root);
    final child1 = root.derivePath("m/44'/60'/0'/0/0");
    final privateKay = HEX.encode(child1.privateKey);
    print(privateKay);


    final private = EthPrivateKey.fromHex(privateKay);
    final address = await private.extractAddress();
    
    // setScore(privateKay);
    print("address: $address");

    getScore();



  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
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
      body: Center(
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
            Text(
              'This is score ' +scoreContract.toString(),
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
