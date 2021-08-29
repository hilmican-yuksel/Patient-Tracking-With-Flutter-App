
class Arsiv {
  
  String date;
  String meter;
  String userId;
  
Arsiv(this.date, this.meter,this.userId);
  Arsiv.fromMap(Map snapshot)
      : date = snapshot['date'] ?? '',
        meter = snapshot['meter'] ?? 0,
        userId = snapshot['userId'] ?? 0;
  toJson() {
    return {
      'date': date,
      'meter': meter,
      'userId': userId,
    };
  }
}