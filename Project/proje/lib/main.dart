import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hilmican_proje/history.dart';
import 'package:hilmican_proje/login.dart';
import 'package:hilmican_proje/maps.dart';
import 'package:hilmican_proje/model/characteristics_ble.dart';
import 'package:hilmican_proje/model/hasta.dart';
import 'package:hilmican_proje/model/hastaListModel.dart';
import 'package:hilmican_proje/services/bluetooth_services.dart';
import 'package:hilmican_proje/services/local_notification.dart';
import 'package:mailer/mailer.dart'; // Mail göndermek için kullanıyoruz
import 'package:mailer/smtp_server.dart'; //SMTP SERVER oluşturmak için kullanıyoruz
import 'package:workmanager/workmanager.dart';

const fetchBackground = "fetchBackground";
final LocalNotification _localNotification = new LocalNotification();
double hastaSiniri = 20;
bool hastaAlarm = false;
HastaListModel hastaListModel = HastaListModel();
final databaseRef = FirebaseDatabase.instance.reference(); //database reference object
String username = "hilmicanyuksel7@gmail.com";
String password = "stqpbyfwqmavkfpm";
const String temasliID = "ff:ff:aa:00:4a:a0";
final smtpServer = gmail(username, password);
User user;
DateTime lastMailDate, lastLocalMsg, lastLocationMessage;
String titleVal = "";

//withServices: [new Guid(BleCharacteristics.getUID())]
void main() async {
    WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
  // FlutterBlue.instance.scan(allowDuplicates: true, withServices: [
  //   new Guid(BleCharacteristics.getUID())
  // ]).listen((scanResult) {
  //   // Bluetooth scan başlıyor ve dönen sonuçlar dinleniyor. yeni cihaz gelirse
  //   checkRssi(scanResult); // Rssi seviyesi kontrol ediliyor.
  // });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // debug etiketini gizlemek için
      title: 'Hilmican', // ekran title
      theme: ThemeData(
        primarySwatch: Colors.blue, // bar rengini mavi yaptım
        visualDensity: VisualDensity
            .adaptivePlatformDensity, // Android ya da IOS a göre görünürlük ayarlar
      ),
      home: LoginPageNew(), // Anasayfa clasını tanımlıyoruz.
    );
  }
}

class HilmicanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.redAccent,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              // eğer telefonun bluetooth u açıksa
              return FindDevicesScreen(); // cihaz tarama ekranı açılır.
            }
            return BluetoothOffScreen(
                state:
                    state); // bluetooth kapalı ise açmaya Bluetooth uyarı ekranı açılır.
          }),
    );
  }
}

void checkRssi(ScanResult scanResult) {
  if (scanResult.advertisementData.serviceUuids.isNotEmpty &&
      scanResult.advertisementData.serviceUuids.first
              .toString()
              .toUpperCase() ==
          BleCharacteristics.getUID()) {
    // eğer dönen cihaz bizim tanımladığımız BLECharacteristics clasında ki beacon uuID sine eşit ise mesafesine göre uyarı mesajı çıkartıyoruz.
    if (scanResult.rssi >= -80) {
      if (lastLocalMsg == null) {
        lastLocalMsg = DateTime.now();
        if (scanResult.device.id.toString().toLowerCase() == temasliID) {
          _localNotification.sendNow(
              "Dikkatli Olun !", "Yakınlarda covid19 Temaslı var", "click");
        } else {
          _localNotification.sendNow(
              "Dikkatli Olun !", "Yakınlarda covid19 Hastası var", "click");
        }
      } else {
        var now = DateTime.now();
        var tempDate = lastLocalMsg.add(Duration(minutes: 2));
        if (now.isAfter(tempDate)) {
          lastLocalMsg = null;
        }
      }
    }
  }
}

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({Key key, this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  _FindDevicesScreenState createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  var auth = FirebaseAuth.instance;
  @override
  void initState() {
    user = auth.currentUser;
    new Timer.periodic(Duration(seconds: 3), checkDistanceInMeter);
    if (user != null) {
      setState(() {
        titleVal = user.email;
      });
    }
    super.initState();
  }

  checkDistanceInMeter(Timer t) {
    getHasta(user).then((hasta) {
      if (hastaListModel.hasta != null) {
        _getCurrentLocation().then((currentLocation) {
          var _distanceInMeters = Geolocator.distanceBetween(
            currentLocation.latitude,
            currentLocation.longitude,
            hastaListModel.hasta.enlem,
            hastaListModel.hasta.boylam,
          );
          if (_distanceInMeters > hastaSiniri) {
            if (lastLocationMessage == null) {
              lastLocationMessage = DateTime.now();
              sendMail("${hastaListModel.hasta.adsoyad} hastanın karantina sınırlarından uzaklaştığı tespit edildi",
                    "Sayın Yetkili, \n ${DateTime.now()} tarihinde ${hastaListModel.hasta.adsoyad} isimli hasta kuralları çiğneyerek evden uzaklaştı.");
              _localNotification.sendNow(
                  "Tehlike !",
                  "Sayın ${hastaListModel.hasta.adsoyad}, Lütfen evinize dönün.",
                  "click");
              hastaAlarm = true;
            } else {
              var now = DateTime.now();
              var tempDate = lastLocationMessage.add(Duration(minutes: 2));
              if (now.isAfter(tempDate)) {
                lastLocationMessage = null;
              }
            }
          } else {
            if (hastaAlarm) {
              _localNotification.sendNow(
                  "Sağlık İçin !",
                  "Sayın ${hastaListModel.hasta.adsoyad}, Kurallara uyduğunuz için teşekkürler.",
                  "click");
                  sendMail("${hastaListModel.hasta.adsoyad} güvenilir bölge sınırlarında.",
                    "Sayın Yetkili, \n ${DateTime.now()} tarihinde ${hastaListModel.hasta.adsoyad} karantina sınırlarına geri döndü");
              hastaAlarm = false;
            }
          }
          createUserData(currentLocation); // database add
        });
      }
    });
    
  }
  createUserData(Position loc){
      //databaseRef.push().set({'adsoyad': hastaListModel.hasta.adsoyad, 'enlem': hastaListModel.hasta.enlem, 'boylam': hastaListModel.hasta.boylam});
      databaseRef.child(hastaListModel.hasta.id).set({'adsoyad': hastaListModel.hasta.adsoyad, 'enlem': loc.latitude, 'boylam': loc.longitude});
  }
  sendMail(String subject,String text) async {
    // Create our email message.
  final message = Message()
    ..from = Address(username)
    ..recipients.add('can66hilmibill@gmail.com') //recipent email
    ..subject =subject
    ..text = text;
    try {
      final sendReport = await send(message, smtpServer);
    } on MailerException catch (e) {
      // e.toString() will show why the email is not sending
    }
  }

  Future<Position> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high); // telefonun mevcut lokasyonunu çekmek için
    return position;
  }

  Future<Hasta> getHasta(User user) async {
    await hastaListModel.isHasta(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titleVal),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Geçmiş',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HistoryPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_sharp),
            tooltip: 'Harita',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MapScreen(
                            hasta: hastaListModel.hasta,
                          )));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
            onPressed: () {
              FirebaseAuth.instance.signOut().then((_) {
                Workmanager.cancelAll();
                hastaListModel.hasta=null;
                Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                LoginPageNew()));
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => null,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map((d) => ListTile(
                            title: Text(d.name),
                            subtitle: Text(d.id.toString()),
                            trailing: StreamBuilder<BluetoothDeviceState>(
                              stream: d.state,
                              initialData: BluetoothDeviceState.disconnected,
                              builder: (c, snapshot) {
                                if (snapshot.data ==
                                    BluetoothDeviceState.connected) {
                                  return RaisedButton(
                                    child: Text('OPEN'),
                                    onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                DeviceScreen(device: d))),
                                  );
                                }
                                return Text(snapshot.data.toString());
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data.map(
                    (r) {
                      return ScanResultTile(
                        result: r,
                        onTap: () {
                          _connect(r.device, c);
                        },
                      );
                    },
                  ).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance.scan(
                        allowDuplicates: true,
                        withServices: [
                          new Guid(BleCharacteristics.getUID())
                        ]).listen((scanResult) {
                      checkRssi(scanResult);
                    }),
                backgroundColor: Colors.green);
          }
        },
      ),
    );
  }
}

// Eğer bluetooth açık değilse aktif olur
class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);
  final BluetoothState state;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth bağlantısını açınız !',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

void sendMailtoManager(BluetoothDevice device) async {
  String hastaBilgisi = "";
  if (device.id.toString().toLowerCase() == temasliID) {
    hastaBilgisi = "Temaslının";
  } else {
    hastaBilgisi = "Hastanın";
  }
  // Create our email message.
  final message = Message()
    ..from = Address(username)
    ..recipients.add('can66hilmibill@gmail.com') //recipent email
    ..subject =
        '${device.id}"li $hastaBilgisi Bağlantısı Koptu :: ${DateTime.now()}' //subject of the email
    ..text = 'Bağlantı Kopma Zamanı :: ${DateTime.now()}';
  try {
    if (lastMailDate == null) {
      lastMailDate = DateTime.now();
      final sendReport = await send(message, smtpServer);
    }
  } on MailerException catch (e) {
    // e.toString() will show why the email is not sending
  }
}

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key key, this.device}) : super(key: key);
  final BluetoothDevice device;
  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool isActive = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        automaticallyImplyLeading: true,
        elevation: 0.1,
        backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: widget.device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () {
                    _disconnect(widget.device, c);
                  };
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => {_connect(widget.device, c)};
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return FlatButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: Center(
          child: Column(children: <Widget>[
        StreamBuilder<BluetoothDeviceState>(
            stream: widget.device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) => snapshot.data ==
                    BluetoothDeviceState.connected // bluetooth bağlantısı varsa
                ? Center(
                    child: Container(
                        height: 80,
                        width: double.infinity,
                        decoration: new BoxDecoration(
                          borderRadius: new BorderRadius.circular(50.0),
                          color: Colors.black,
                        ),
                        child: !isActive
                            ? FlatButton.icon(
                                textColor: Colors.green,
                                onPressed: () {
                                  BluetoothServices.writeToDevice(
                                      isActive, widget.device);
                                  setState(() {
                                    isActive = true;
                                  });
                                },
                                icon: Icon(Icons.car_rental, size: 18),
                                label: Text("ON ALARM"),
                              )
                            : FlatButton.icon(
                                textColor: Colors.red,
                                onPressed: () {
                                  BluetoothServices.writeToDevice(
                                      isActive, widget.device);
                                  setState(() {
                                    isActive = false;
                                  });
                                },
                                icon: Icon(Icons.car_rental, size: 18),
                                label: Text("OFF ALARM"),
                              )))
                : Container(child: null)),
      ])),
    );
  }
}

// Bir tane widget yazdım. Bluetooth cihazları bulunduğu zaman listelemek için kullanıyoruz. Her satır için 1 tane build ediyoruz.
class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);
  final ScanResult result; // widget çağırılırken dolduruluyor.
  final VoidCallback onTap; //
  // İsim dönen widget
  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      // Eğer cihaza tanımlı bir name varsa Onu yazıyorum.
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      // Eğer cihaza isim tanımlı değilse cihaz ID sini yazıyorum..
      return Text(result.device.id.toString());
    }
  }

  // Aşağıya doğru açılan bir Widget yazıcaz. Buda o widget da her bir satırda çağırılmak için hazırladık.
  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

// characteristik ve servisler için
  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

// cihaz manufacture data bilgileri
  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

// Cihaz servis bilgisi
  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

// GENEL Widget hazırlanır.
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: RaisedButton(
        child: Text('Connect'),
        color: Colors.black,
        textColor: Colors.white,
        onPressed:
            (result.advertisementData.connectable) ? onTap : onTap, //null,
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(
            context,
            'Manufacturer Data',
            getNiceManufacturerData(
                    result.advertisementData.manufacturerData) ??
                'N/A'),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData) ?? 'N/A'),
      ],
    );
  }
}

// seçilen cihaza bağlantı kurmak için.
void _connect(BluetoothDevice device, BuildContext context) async {
  await device.connect(timeout: Duration(seconds: 5), autoConnect: false);

  List<BluetoothDevice> connectedDevices =
      await FlutterBlue.instance.connectedDevices;

  if (connectedDevices.contains(device)) {
    BleCharacteristics.addConnectedDevice(device);
    device.state.listen((event) {
      switch (event) {
        case BluetoothDeviceState.connected:
          lastMailDate = null;
          break;
        case BluetoothDeviceState.disconnected:
          sendMailtoManager(device);
          break;
        default:
          break;
      }
    });
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DeviceScreen(device: device)));
  }
}

void _disconnect(BluetoothDevice device, BuildContext context) async {
  await device.disconnect();

  List<BluetoothDevice> connectedDevices = [];

  if (connectedDevices.contains(device)) {
    BleCharacteristics.removeConnectedDevice(device);
  }
}
