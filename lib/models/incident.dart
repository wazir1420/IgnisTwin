class TimelineEntry {
  final DateTime time = DateTime.now();
  final String text;
  TimelineEntry(this.text);
}

class Incident {
  final String id;
  final DateTime start = DateTime.now();
  DateTime? end;
  bool acknowledged = false;
  final bool simulated;
  final List<TimelineEntry> timeline = [];

  Incident(this.id, this.simulated);

  bool get isActive => end == null;
  Duration get duration => (end ?? DateTime.now()).difference(start);
}
