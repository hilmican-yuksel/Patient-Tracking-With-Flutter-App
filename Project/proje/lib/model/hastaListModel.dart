import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hilmican_proje/model/hasta.dart';

class HastaListModel{
  Hasta hasta;
  Future<Hasta> isHasta(String id) async{
    try {
    await FirebaseFirestore.instance.collection("HastaLokasyonlari").doc(id).get().then((value) {
      hasta = Hasta.fromMap(value.data(), value.id);
    });  
    } catch (e) {
    }
  }
}