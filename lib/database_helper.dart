import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'carpool.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Create the users table for login, registration, and password retrieval
    await db.execute('''
      CREATE TABLE users (
        userID INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        security_question TEXT NOT NULL,
        security_answer TEXT NOT NULL
      )
    ''');

    // Create the carpools table
    await db.execute('''
      CREATE TABLE carpools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreID TEXT,
        userID INTEGER NOT NULL,
        pickUpPoint TEXT NOT NULL,
        dropOffPoint TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        availableSeats INTEGER NOT NULL,
        ridePreference TEXT,
        status TEXT DEFAULT 'active',
        earnings REAL DEFAULT 0.0,
        FOREIGN KEY(userID) REFERENCES users(userID)
      )
    ''');

    // Create the carpool history table
    await db.execute('''
      CREATE TABLE carpool_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carpoolID INTEGER NOT NULL,
        userID INTEGER NOT NULL,
        status TEXT,
        earnings REAL DEFAULT 0.0,
        FOREIGN KEY(carpoolID) REFERENCES carpools(id),
        FOREIGN KEY(userID) REFERENCES users(userID)
      )
    ''');

    await db.execute('''
      CREATE TABLE rides (
        rideID INTEGER PRIMARY KEY AUTOINCREMENT,
        carpoolID INTEGER NOT NULL,
        userID INTEGER NOT NULL, -- passenger
        status TEXT DEFAULT 'requested',  -- requested, confirmed, completed, canceled
        pickupNote TEXT,
        FOREIGN KEY(carpoolID) REFERENCES carpools(id),
        FOREIGN KEY(userID) REFERENCES users(userID)
      )
    ''');
  }

  // Anonymous sign-in method
  Future<User?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      User? user = userCredential.user;
      print('Anonymous user UID: ${user?.uid}');
      return user;
    } catch (e) {
      print('Failed to sign in anonymously: $e');
      return null;
    }
  }

  // Insert a new user
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;

    // Insert user into SQLite
    int userID = await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insert into Firestore
    try {
      await FirebaseFirestore.instance.collection('users').add({
        'userID': userID, // SQLite-generated ID
        'username': user['username'],
        'email': user['email'],
        'password': user['password'], // NOTE: avoid storing plain passwords in production
        'security_question': user['security_question'],
        'security_answer': user['security_answer'],
      });
    } catch (e) {
      print('Failed to insert user into Firestore: $e');
    }

    return userID;
  }

  // Update the carpool status (completed or canceled)
  Future<void> updateCarpoolStatus(int carpoolID, String status) async {
    final db = await database;
    await db.update(
      'carpools',
      {'status': status},
      where: 'id = ?',
      whereArgs: [carpoolID],
    );
  }

// Insert a new carpool into both SQLite and Firestore
  Future<int> insertCarpool(Map<String, dynamic> carpool) async {
    final db = await database;

    // Insert into Firestore first, Firestore automatically generates an ID
    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('carpools').add({
        'userID': carpool['userID'],
        'pickUpPoint': carpool['pickUpPoint'],
        'dropOffPoint': carpool['dropOffPoint'],
        'date': carpool['date'],
        'time': carpool['time'],
        'availableSeats': carpool['availableSeats'],
        'ridePreference': carpool['ridePreference'],
        'status': carpool['status'],
        'earnings': carpool['earnings'],
      });

      // After successfully adding to Firestore, insert the rest into SQLite
      Map<String, dynamic> carpoolData = {
        'userID': carpool['userID'],
        'pickUpPoint': carpool['pickUpPoint'],
        'dropOffPoint': carpool['dropOffPoint'],
        'date': carpool['date'],
        'time': carpool['time'],
        'availableSeats': carpool['availableSeats'],
        'ridePreference': carpool['ridePreference'],
        'status': carpool['status'],
        'earnings': carpool['earnings'],
        'firestoreID': docRef.id,
      };

      // Insert into SQLite, no need to store Firestore ID here
      int carpoolID = await db.insert(
        'carpools',
        carpoolData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return carpoolID;  // Return SQLite ID for future references
    } catch (e) {
      print('Failed to insert carpool: $e');
      return -1;  // Return error code if Firestore insert fails
    }
  }

  Future<int> insertRide(Map<String, dynamic> ride) async {
    final db = await database;

    // Insert ride into SQLite
    int rideID = await db.insert('rides', ride, conflictAlgorithm: ConflictAlgorithm.replace,);

    // Insert ride into Firestore
    try {
      await FirebaseFirestore.instance.collection('rides').add({
        'carpoolID': ride['carpoolID'],
        'userID': ride['userID'],
        'status': ride['status'],
        'pickupNote': ride['pickupNote'],
      });
    } catch (e) {
      print('Failed to insert ride into Firestore: $e');
    }

    return rideID;
  }

  // Get user by email (used for login and password retrieval)
  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Get all rides by passenger
  Future<List<Map<String, dynamic>>> getRidesByPassenger(int userID) async {
    final db = await database;
    return await db.query('rides', where: 'userID = ?', whereArgs: [userID]);
  }

  // Get confirmed passengers for a carpool
  Future<List<Map<String, dynamic>>> getConfirmedRidesForCarpool(int carpoolID) async {
    final db = await database;
    return await db.query(
      'rides',
      where: 'carpoolID = ? AND status = ?',
      whereArgs: [carpoolID, 'confirmed'],
    );
  }

  Future<String> requestRide(int carpoolID, int userID, {String pickupNote = ''}) async {
    final db = await database;
    try {
      await db.insert('rides', {
        'carpoolID': carpoolID,
        'userID': userID,
        'pickupNote': pickupNote,
        'status': 'Requested',  // <-- Not Confirmed!
      });
      return 'Ride requested successfully!';
    } catch (e) {
      return 'Failed to request ride: $e';
    }
  }

  // Cancel a confirmed ride
  Future<bool> cancelRide(int carpoolID, int userID) async {
    final db = await database;

    // Check if a confirmed ride exists
    final existing = await db.query(
      'rides',
      where: 'carpoolID = ? AND userID = ? AND status = ?',
      whereArgs: [carpoolID, userID, 'Requested'],
    );

    if (existing.isEmpty) return false; // No confirmed ride found

    // Update the ride status to 'canceled'
    await db.update(
      'rides',
      {'status': 'canceled'},
      where: 'carpoolID = ? AND userID = ?',
      whereArgs: [carpoolID, userID],
    );

    return true;
  }

  // Expire a pending ride if it hasn't been confirmed in 3 minutes
  Future<bool> expireRide(int carpoolID, int userID) async {
    final db = await database;

    // Check if a pending ride exists (not yet confirmed)
    final existing = await db.query(
      'rides',
      where: 'carpoolID = ? AND userID = ? AND status = ?',
      whereArgs: [carpoolID, userID, 'Requested'],
    );

    if (existing.isEmpty) return false; // No pending ride found

    // Update the ride status to 'expired'
    await db.update(
      'rides',
      {'status': 'expired'},
      where: 'carpoolID = ? AND userID = ?',
      whereArgs: [carpoolID, userID],
    );

    return true;
  }

  // Get all carpools from the database
  Future<List<Map<String, dynamic>>> getAllCarpools() async {
    final db = await database;
    return await db.query('carpools');
  }

  // Update user password
  Future<void> updateUserPassword(String email, String newPassword) async {
    final db = await database;
    await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // Update ride status (e.g., to confirmed or canceled)
  Future<void> updateRideStatus(int rideID, String status) async {
    final db = await database;
    await db.update('rides', {'status': status}, where: 'rideID = ?', whereArgs: [rideID]);
  }

  // Fetch all completed or canceled carpools for the user in carpool history
  Future<List<Map<String, dynamic>>> getCarpoolHistory(int userID) async {
    final db = await database;
    return await db.query(
      'carpool_history',
      where: 'userID = ? AND (status = ? OR status = ?)',  // Completed or Canceled
      whereArgs: [userID, 'completed', 'canceled'],
      orderBy: 'status DESC',  // Order by status (completed first, then canceled)
    );
  }

  // Fetch active carpools for the Registered Carpool page
  Future<List<Map<String, dynamic>>> getCarpools(int userID) async {
    final db = await database;
    return await db.query(
      'carpools',
      where: 'userID = ? AND status = ?',
      whereArgs: [userID, 'active'],
      orderBy: 'date DESC',
    );
  }

  // Insert carpool history (either completed or canceled)
  Future<void> addCarpoolHistory(int carpoolID, int userID, String status, double earnings) async {
    final db = await database;
    await db.insert(
      'carpool_history',
      {
        'carpoolID': carpoolID,
        'userID': userID,
        'status': status,
        'earnings': earnings,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUserData(String originalEmail, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'users',
      updates,
      where: 'email = ?',
      whereArgs: [originalEmail],
    );
  }

  // Get list of drivers from completed rides for rating
  Future<List<Map<String, dynamic>>> getCompletedDriversForRating(int userID) async {
    final db = await database;

    return await db.rawQuery('''
    SELECT ch.id as historyID, cp.id as carpoolID, cp.userID as driverID, u.username as driverName
    FROM carpool_history ch
    JOIN carpools cp ON ch.carpoolID = cp.id
    JOIN users u ON cp.userID = u.userID
    WHERE ch.userID = ? AND ch.status = 'completed'
  ''', [userID]);
  }

// Submit or update driver's average rating and review count
  Future<void> submitDriverRating(int driverID, double newRating) async {
    final db = await database;

    final result = await db.query(
      'users',
      columns: ['rating', 'reviewCount'],
      where: 'userID = ?',
      whereArgs: [driverID],
    );

    if (result.isNotEmpty) {
      final current = result.first;
      double oldRating = current['rating'] != null ? current['rating'] as double : 0.0;
      int reviewCount = current['reviewCount'] != null ? current['reviewCount'] as int : 0;

      double updatedRating = ((oldRating * reviewCount) + newRating) / (reviewCount + 1);

      await db.update(
        'users',
        {
          'rating': updatedRating,
          'reviewCount': reviewCount + 1,
        },
        where: 'userID = ?',
        whereArgs: [driverID],
      );
    }
  }

  // Fetch data from Firestore and overwrite SQLite
  Future<void> updateSQLiteFromFirestore() async {
    try {
      // Fetch all documents from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('carpools').get();

      // Convert Firestore documents into a list of maps
      List<Map<String, dynamic>> allRides = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['firestoreID'] = doc.id; // Optional: Store the Firestore document ID in SQLite
        return data;
      }).toList();

      final db = await database;

      // Clear the existing data in the 'carpools' table before inserting new data
      await db.delete('carpools');

      // Insert the new Firestore data into SQLite
      for (var ride in allRides) {
        await db.insert(
          'carpools',
          ride,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      print('SQLite updated with Firestore data.');
    } catch (e) {
      print('Error updating SQLite from Firestore: $e');
    }
  }

  // Fetch active rides from SQLite
  Future<List<Map<String, dynamic>>> getActiveCarpools({
    required String fromLocation,
    required String toLocation,
    required int seatCount,
    required bool musicPreference,
    required bool petFriendly,
    required bool nonSmoking,
  }) async {
    final db = await database;

    // Fetch active carpools from SQLite
    List<Map<String, dynamic>> allRides = await db.query(
      'carpools',
      where: 'status = ?',
      whereArgs: ['active'],
    );

    // Apply filtering based on the user's preferences
    List<Map<String, dynamic>> filteredRides = allRides.where((ride) {
      bool locationMatch =
          ride['pickUpPoint'] == fromLocation && ride['dropOffPoint'] == toLocation;

      bool preferenceMatch = true;
      if (musicPreference) {
        preferenceMatch &= ride['ridePreference']?.toString().contains('Music') ?? false;
      }
      if (petFriendly) {
        preferenceMatch &= ride['ridePreference']?.toString().contains('Pet') ?? false;
      }
      if (nonSmoking) {
        preferenceMatch &= ride['ridePreference']?.toString().contains('Non-Smoking') ?? false;
      }

      bool seatAvailable = (ride['availableSeats'] ?? 0) >= seatCount;

      return locationMatch && preferenceMatch && seatAvailable;
    }).toList();

    return filteredRides;
  }


}
