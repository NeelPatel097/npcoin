import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:npcoin/slider_widget.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'NPCOIN'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Client httpClient;
  Web3Client ethClient;
  bool data = false;
  int myAmount = 0;
  final myAddress = "0x8E37939AD281bd40FBEF0e90c39680A98A0AE442";
  String txHash;
  var myData;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(
        "https://rinkeby.infura.io/v3/244117442141432da134cd0512739624",
        httpClient);
    getBalance(myAddress);
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0x9F5e4057d97ADb40aD4242F4c3F7C1029952CCE2";

    final contract = DeployedContract(ContractAbi.fromJson(abi, "NPCoin"),EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async{
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(contract: contract, function: ethFunction, params: args);

    return result;

  }

  Future<void> getBalance(String targetAddress) async{
    // EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    List<dynamic> result = await query("getBalance", []);

    myData = result[0];
    data = true;
    setState(() {});
  }

  Future<String> submit(String functionName, List<dynamic> args)async{
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        "c5172429c15560ae2d930de9d6e62f3d422dd531b3aa0f3af5355a4bc0fcc15b");

    DeployedContract contract = await loadContract();

    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(credentials, Transaction.callContract(contract: contract,
        function: ethFunction, parameters: args),
    fetchChainIdFromNetworkId: true);

    return result;
  }

  Future<String> sendCoin()async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("depositBalance", [bigAmount]);

    print("Deposited");
    txHash = response;
    setState(() {});
    return response;
  }

  Future<String> withdrawCoin()async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("withdrawBalance", [bigAmount]);

    print("Withdrawn");
    txHash = response;
    setState(() {});
    return response;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vx.gray300,
      body: ZStack([
        VxBox()
            .blue600
            .size(context.screenWidth, context.percentHeight*30)
            .make(),

        VStack([
          (context.percentHeight * 10).heightBox,
          "\$NPCOIN".text.xl4.white.bold.center.makeCentered().py16(),
          (context.percentHeight * 5).heightBox,
          VxBox(child: VStack([
              "Balance".text.gray700.xl2.semiBold.makeCentered(),
              10.heightBox,
              data?"\$$myData".text.bold.xl6.makeCentered()
                  :CircularProgressIndicator().centered()
          ]))
              .p16
              .white
              .size(context.screenWidth, context.percentHeight * 18)
              .rounded
              .shadowXl
              .make()
              .p16(),
          30.heightBox,

          SliderWidget(
            min: 0,
            max: 100,
            finalVal: (value) {
              myAmount = (value*100).round();
              print(myAmount);
            },
          ).centered(),

          HStack([
            FlatButton.icon(
              onPressed: ()=> getBalance(myAddress),
              color: Colors.blue,
              shape: Vx.roundedSm,
              icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
              ),
              label: "Refresh".text.white.make()
            ).h(50),
            FlatButton.icon(
                onPressed: () => sendCoin(),
                color: Colors.green,
                shape: Vx.roundedSm,
                icon: Icon(
                  Icons.call_made_outlined,
                  color: Colors.white,
                ),
                label: "Deposit".text.white.make()
            ).h(50),
            FlatButton.icon(
                onPressed: () => withdrawCoin(),
                color: Colors.red,
                shape: Vx.roundedSm,
                icon: Icon(
                  Icons.call_received_outlined,
                  color: Colors.white,
                ),
                label: "Withdraw".text.white.make()
            ).h(50)
          ],
            alignment: MainAxisAlignment.spaceAround,
            axisSize: MainAxisSize.max,
          ).p16(),
          if (txHash!=null) txHash.text.black.makeCentered().p16()
        ])
      ]),
    );
  }
}
