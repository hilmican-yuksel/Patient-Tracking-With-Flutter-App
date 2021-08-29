
class Hasta {
  
  String id;
  String adsoyad;
  double enlem;
  double boylam;
Hasta(this.id, this.adsoyad,this.enlem,this.boylam);
  Hasta.fromMap(Map snapshot,String id)
      : id = id ?? '',
        adsoyad = snapshot['adsoyad'] ?? '',
        enlem = snapshot['enlem'] ?? 0,
        boylam = snapshot['boylam'] ?? 0;
  toJson() {
    return {
      'adsoyad': adsoyad,
      'enlem': enlem,
      'boylam': boylam,
    };
  }
}