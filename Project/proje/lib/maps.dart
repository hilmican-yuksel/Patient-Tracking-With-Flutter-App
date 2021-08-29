import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hilmican_proje/model/hasta.dart';
import 'package:hilmican_proje/model/hastaListModel.dart';
import 'package:hilmican_proje/services/local_notification.dart';

final LocalNotification _localNotification = new LocalNotification();
DateTime lastDangerDate;

class MapScreen extends StatefulWidget {
  const MapScreen({Key key, this.hasta}) : super(key: key);
  final Hasta hasta;
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController mapController;
  BitmapDescriptor iconMarker;

  //Maps
  final databaseRef =
      FirebaseDatabase.instance.reference(); //database reference object
  Set<Marker> _markers = HashSet<Marker>();
  Set<Circle> _circles = HashSet<Circle>();
  double hastaSiniri = 20;
  DateTime lastLocationMessage;
  // End Maps
  User user;
  HastaListModel hastaListModel = HastaListModel();
  CameraPosition _initialPosition = CameraPosition(
      target: LatLng(39.9477878, 32.825929),
      zoom: 6); // harita sayfası ilk açılışında lokasyon ayarlama
  void _onMapCreated(GoogleMapController controller) {
    // harita controller haritayı uygulama çalışırken kontrol etmek için.
    setState(() {
      mapController = controller;
    });
  }

  @override
  void initState() {
    // init state açılan sayfada ilk çalışacak olan override fonksiyon
    user = FirebaseAuth.instance.currentUser;
    getAllLocations().then((value) {
      if (widget.hasta != null) {
        setCustomMapPin().then((value) {
          _getUserLocation();
          setState(() {
            _setMarkers(
                LatLng(widget.hasta.enlem, widget.hasta.boylam), user.uid,
                icon: iconMarker);
            _setCircles(
                LatLng(widget.hasta.enlem, widget.hasta.boylam), user.uid);
          });
        });
      }
      new Timer.periodic(Duration(seconds: 10), refreshMarkers);
    });

    super.initState();
  }

  void sendMessage(String meter) {
    if (lastDangerDate == null) {
      lastDangerDate = DateTime.now();
      _localNotification.sendNow(
          "Dikkatli Olun !", "$meter metre yakınlarda covid19 Hastası var", "click");
         // Geçmişe kayıt et. 
         saveHistory(meter,lastDangerDate);
    } else {
      var now = DateTime.now();
      var tempDate = lastDangerDate.add(Duration(minutes: 2));
      if (now.isAfter(tempDate)) {
        lastDangerDate = null;
      }
    }
  }
  void saveHistory(String meter,DateTime date){
    Map<String,String> history = {
      "userId" : user.uid,
      "date" : date.toString(),
      "meter" : meter
    };

    FirebaseFirestore.instance.collection("ArsivGecmisi").add(history);
  }
  void refreshMarkers(Timer t) {
    _markers.clear();
    if (widget.hasta != null) {
      _setMarkers(LatLng(widget.hasta.enlem, widget.hasta.boylam), user.uid,
          icon: iconMarker);
    }
    getAllLocations().then((value) {
      setState(() {});
    });
  }



  Future getAllLocations() async {
    databaseRef.once().then((DataSnapshot snapshot) {
      for (final key in snapshot.value.keys) {
        Map<dynamic, dynamic> item = snapshot.value[key];
        Hasta hasta = Hasta.fromMap(item, key);
        if (key != user.uid) {
          _getCurrentLocation().then((position) {
            if (_getMeterDiff(position, hasta) <= hastaSiniri * 2) {
              sendMessage(_getMeterDiff(position, hasta).toStringAsFixed(1));
              _setMarkers(LatLng(hasta.enlem, hasta.boylam), hasta.id);
              setState(() {});
            }
          });
        }
        setState(() {});
      }
    });
  }

  double _getMeterDiff(Position currentLocation, Hasta hasta) {
    return Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      hasta.enlem,
      hasta.boylam,
    );
  }

  Future setCustomMapPin() async {
    iconMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        'assets/images/house_icon.png');
    return iconMarker;
  }

  void _setMarkers(LatLng point, String markerId,
      {BitmapDescriptor icon = null}) {
    if (icon == null) {
      _markers.add(Marker(markerId: MarkerId(markerId), position: point));
    } else {
      _markers.add(
          Marker(markerId: MarkerId(markerId), position: point, icon: icon));
    }
  }

  void _setCircles(LatLng point, circleId) {
    _circles.add(Circle(
        circleId: CircleId(circleId),
        center: point,
        radius: hastaSiniri,
        fillColor: Colors.redAccent.withOpacity(0.5),
        strokeWidth: 3,
        strokeColor: Colors.redAccent));
  }

  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high); // telefonun mevcut lokasyonunu çekmek için
  }

  void _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high); // telefonun mevcut lokasyonunu çekmek için
    setState(() {
      _initialPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 18); // haritanın pozisyonunu mevcut lokasyona eşitliyoruz
      mapController.animateCamera(CameraUpdate.newCameraPosition(
          _initialPosition)); // haritayı mevcut lokasyona animasyonlu bir şekilde zoomluyoruz.
    });
  }

  @override
  Widget build(BuildContext context) {
    // GoogleMap i Scaffold da kullanmak için final olarak tanımladım. Scaffoldun karışık olmasını önledim.
    final makeMap = GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: _onMapCreated,
        markers: _markers,
        circles: _circles,
        myLocationEnabled: true,
        mapType: MapType.normal);
    // AppBar ı Scaffold da kullanmak için final olarak tanımladım. Scaffoldun karışık olmasını önledim.
    final appBar = AppBar(
      title: Text("Harita"),
      automaticallyImplyLeading: true,
      elevation: 0.1,
      backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context, false),
      ),
    );
    //var hastaListModel = Provider.of<HastaListModel>(context);
    return Scaffold(
      appBar: appBar,
      body: makeMap,
    );
  }
}
