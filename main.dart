import 'dart:io';

class InputEnded implements Exception {}

mixin Timestamped {
  DateTime? _createdAt;

  void markCreated() {
    _createdAt = DateTime.now();
  }

  String get createdLabel {
    final t = _createdAt;
    if (t == null) return 'n/a';
    return '${t.year}-${_two(t.month)}-${_two(t.day)} ${_two(t.hour)}:${_two(t.minute)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

abstract class CenterRecord with Timestamped {
  final String _id;
  String _name;

  CenterRecord(this._id, String name) : _name = name.trim() {
    if (_name.isEmpty) throw ArgumentError('Name cannot be empty.');
    markCreated();
  }

  String get id => _id;
  String get name => _name;

  set name(String value) {
    if (value.trim().isEmpty) throw ArgumentError('Name cannot be empty.');
    _name = value.trim();
  }

  String get category;

  String describe();
}

abstract class LearningResource extends CenterRecord {
  final int _totalCopies;
  int _availableCopies;
  final double _dailyFee;

  LearningResource(String id, String name, int copies, double dailyFee)
      : _totalCopies = copies,
        _availableCopies = copies,
        _dailyFee = dailyFee,
        super(id, name) {
    if (copies < 1) throw ArgumentError('Copies must be at least 1.');
    if (dailyFee < 0) throw ArgumentError('Fee cannot be negative.');
  }

  int get totalCopies => _totalCopies;
  int get availableCopies => _availableCopies;
  double get dailyFee => _dailyFee;
  bool get isAvailable => _availableCopies > 0;

  void borrow() {
    if (!isAvailable) throw StateError('No copies of "$name" are available.');
    _availableCopies--;
  }

  void giveBack() {
    if (_availableCopies >= _totalCopies) {
      throw StateError('All copies of "$name" are already returned.');
    }
    _availableCopies++;
  }

  double computeFee(int days);
}

class Book extends LearningResource {
  Book(super.id, super.name, super.copies, super.dailyFee);

  @override
  String get category => 'Book';

  @override
  double computeFee(int days) => dailyFee * days;

  @override
  String describe() =>
      '[$id] Book: $name | Copies: $availableCopies/$totalCopies | '
      'Fee/day: ${dailyFee.toStringAsFixed(2)} | Added: $createdLabel';
}

class OnlineCourse extends LearningResource {
  static const int maxBilledDays = 7;

  OnlineCourse(super.id, super.name, super.copies, super.dailyFee);

  @override
  String get category => 'Online Course';

  @override
  double computeFee(int days) =>
      dailyFee * (days > maxBilledDays ? maxBilledDays : days);

  @override
  String describe() =>
      '[$id] Online Course: $name | Seats: $availableCopies/$totalCopies | '
      'Fee/day: ${dailyFee.toStringAsFixed(2)} (max $maxBilledDays days) | '
      'Added: $createdLabel';
}

class Participant extends CenterRecord {
  final List<String> _borrowedIds = [];
  double _totalFees = 0;

  Participant(super.id, super.name);

  @override
  String get category => 'Participant';

  List<String> get borrowedIds => List.unmodifiable(_borrowedIds);
  double get totalFees => _totalFees;

  bool hasBorrowed(String resourceId) => _borrowedIds.contains(resourceId);

  void addLoan(String resourceId) => _borrowedIds.add(resourceId);

  void removeLoan(String resourceId, double fee) {
    _borrowedIds.remove(resourceId);
    _totalFees += fee;
  }

  @override
  String describe() =>
      '[$id] Participant: $name | Active loans: ${_borrowedIds.length} | '
      'Fees paid: ${_totalFees.toStringAsFixed(2)} | Registered: $createdLabel';
}

class CenterManager {
  final Map<String, LearningResource> _resources = {};
  final List<Participant> _participants = [];
  final List<String> _log = [];

  int _resourceCounter = 0;
  int _participantCounter = 0;

  String addResource(
      String type, String name, int copies, double dailyFee) {
    _resourceCounter++;
    final id = 'R${_resourceCounter.toString().padLeft(3, '0')}';
    final resource = type == 'book'
        ? Book(id, name, copies, dailyFee)
        : OnlineCourse(id, name, copies, dailyFee);
    _resources[id] = resource;
    _log.add('${resource.createdLabel} Added ${resource.category} $id');
    return id;
  }

  String registerParticipant(String name) {
    _participantCounter++;
    final id = 'P${_participantCounter.toString().padLeft(3, '0')}';
    final participant = Participant(id, name);
    _participants.add(participant);
    _log.add('${participant.createdLabel} Registered participant $id');
    return id;
  }

  Participant? findParticipant(String id) {
    for (final p in _participants) {
      if (p.id == id) return p;
    }
    return null;
  }

  LearningResource? findResource(String id) => _resources[id];

  void borrow(String participantId, String resourceId) {
    final participant = findParticipant(participantId);
    final resource = findResource(resourceId);
    if (participant == null) throw StateError('Participant not found.');
    if (resource == null) throw StateError('Resource not found.');
    if (participant.hasBorrowed(resourceId)) {
      throw StateError('${participant.name} already has "${resource.name}".');
    }
    resource.borrow();
    participant.addLoan(resourceId);
    _log.add('${participant.id} borrowed $resourceId');
  }

  double giveBack(String participantId, String resourceId, int days) {
    final participant = findParticipant(participantId);
    final resource = findResource(resourceId);
    if (participant == null) throw StateError('Participant not found.');
    if (resource == null) throw StateError('Resource not found.');
    if (!participant.hasBorrowed(resourceId)) {
      throw StateError('${participant.name} has not borrowed "${resource.name}".');
    }
    final fee = resource.computeFee(days);
    resource.giveBack();
    participant.removeLoan(resourceId, fee);
    _log.add('${participant.id} returned $resourceId after $days day(s), '
        'fee ${fee.toStringAsFixed(2)}');
    return fee;
  }

  List<CenterRecord> allRecords() => [..._resources.values, ..._participants];

  List<String> get log => List.unmodifiable(_log);
  bool get hasResources => _resources.isNotEmpty;
  bool get hasParticipants => _participants.isNotEmpty;
}

String? readLine(String prompt) {
  stdout.write(prompt);
  final line = stdin.readLineSync();
  if (line == null) throw InputEnded();
  return line.trim();
}

String readText(String prompt) {
  while (true) {
    final value = readLine(prompt) ?? '';
    if (value.isNotEmpty) return value;
    print('Input cannot be empty. Please try again.');
  }
}

int readInt(String prompt, {int min = 1, int max = 1000000}) {
  while (true) {
    final value = int.tryParse(readLine(prompt) ?? '');
    if (value != null && value >= min && value <= max) return value;
    print('Enter a whole number from $min to $max.');
  }
}

double readDouble(String prompt) {
  while (true) {
    final value = double.tryParse(readLine(prompt) ?? '');
    if (value != null && value >= 0) return value;
    print('Enter a number that is 0 or higher.');
  }
}

void printMenu() {
  print('\n========================================');
  print(' COMMUNITY LEARNING CENTER MANAGEMENT');
  print('========================================');
  print('1. Add learning resource');
  print('2. Register participant');
  print('3. Borrow resource');
  print('4. Return resource');
  print('5. View resources');
  print('6. View participants');
  print('7. View transaction log');
  print('0. Exit');
}

void addResource(CenterManager center) {
  String type = '';
  while (type != 'book' && type != 'course') {
    type = readText('Type (book/course): ').toLowerCase();
    if (type != 'book' && type != 'course') {
      print('Type must be "book" or "course".');
    }
  }
  final name = readText('Resource name: ');
  final copies = readInt('Number of copies or seats: ');
  final fee = readDouble('Fee per day: ');
  final id = center.addResource(type, name, copies, fee);
  print('Resource added with ID $id.');
}

void registerParticipant(CenterManager center) {
  final id = center.registerParticipant(readText('Participant name: '));
  print('Participant registered with ID $id.');
}

void borrowResource(CenterManager center) {
  if (!center.hasParticipants || !center.hasResources) {
    print('Register at least one participant and add one resource first.');
    return;
  }
  final pid = readText('Participant ID: ').toUpperCase();
  final rid = readText('Resource ID: ').toUpperCase();
  center.borrow(pid, rid);
  print('Borrow recorded.');
}

void returnResource(CenterManager center) {
  final pid = readText('Participant ID: ').toUpperCase();
  final rid = readText('Resource ID: ').toUpperCase();
  final days = readInt('Days borrowed: ', min: 1, max: 365);
  final fee = center.giveBack(pid, rid, days);
  print('Return recorded. Fee charged: ${fee.toStringAsFixed(2)}');
}

void showRecords(CenterManager center, String category) {
  final records =
      center.allRecords().where((r) => r.category != 'Participant');
  final selected = category == 'Participant'
      ? center.allRecords().where((r) => r.category == 'Participant')
      : records;
  if (selected.isEmpty) {
    print('No records to display yet.');
    return;
  }
  for (final record in selected) {
    print(record.describe());
  }
}

void showLog(CenterManager center) {
  if (center.log.isEmpty) {
    print('No transactions recorded yet.');
    return;
  }
  for (var i = 0; i < center.log.length; i++) {
    print('${i + 1}. ${center.log[i]}');
  }
}

void main() {
  final center = CenterManager();
  var running = true;

  while (running) {
    try {
      printMenu();
      final choice = readLine('Choose an option: ') ?? '';
      switch (choice) {
        case '1':
          addResource(center);
          break;
        case '2':
          registerParticipant(center);
          break;
        case '3':
          borrowResource(center);
          break;
        case '4':
          returnResource(center);
          break;
        case '5':
          showRecords(center, 'Resource');
          break;
        case '6':
          showRecords(center, 'Participant');
          break;
        case '7':
          showLog(center);
          break;
        case '0':
          running = false;
          print('Thank you for using the system. Goodbye.');
          break;
        default:
          print('Invalid choice. Please enter a number from the menu.');
      }
    } on InputEnded {
      print('\nInput ended. Exiting.');
      running = false;
    } on ArgumentError catch (e) {
      print('Error: ${e.message}');
    } on StateError catch (e) {
      print('Error: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
    }
  }
}