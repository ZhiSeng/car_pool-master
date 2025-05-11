import 'package:flutter/foundation.dart';
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
        security_answer TEXT NOT NULL,
        rating REAL,
        reviewCount INTEGER,
        ecoPoints INTEGER
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
      carPlateNumber TEXT,  -- New field for car plate number
      carColor TEXT,        -- New field for car color
      carModel TEXT,        -- New field for car model
      FOREIGN KEY(userID) REFERENCES users(userID)
    )
  ''');

    // Create the carpool history table
    await db.execute('''
    CREATE TABLE carpool_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    firestoreID TEXT,
    carpoolID INTEGER NOT NULL,
    userID INTEGER NOT NULL,
    status TEXT,
    earnings REAL DEFAULT 0.0,
    pickUpPoint TEXT,
    dropOffPoint TEXT,
    date TEXT,
    time TEXT,
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
        seat INTEGER NOT NULL,
        musicPreference INTEGER DEFAULT 0,
        petFriendly INTEGER DEFAULT 0,
        nonSmoking INTEGER DEFAULT 0,
        pickupNote TEXT,
        firestoreID TEXT,
        FOREIGN KEY(carpoolID) REFERENCES carpools(id),
        FOREIGN KEY(userID) REFERENCES users(userID)
      )
    ''');

    await db.execute('''
    CREATE TABLE vouchers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      firestoreID TEXT,
      name TEXT NOT NULL,
      description TEXT,
      startDate TEXT,
      endDate TEXT,
      ecoPointsRequired INTEGER,
      redeemedBy TEXT  -- Comma-separated list of userIDs
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

  Future<int> generateUserID() async {
    // Get the current highest userID in Firestore
    final snapshot = await FirebaseFirestore.instance.collection('users').orderBy('userID', descending: true).limit(1).get();

    if (snapshot.docs.isEmpty) {
      return 1; // If there are no users, start from 1
    }

    final highestUserID = snapshot.docs.first['userID'];
    return highestUserID + 1; // Increment the last userID
  }

  // Insert into Firestore and auto-increment userID
  // Modify your insertUser method to auto-generate the userID in SQLite
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;

    user['rating'] = user['rating'] ?? 0.0;
    user['reviewCount'] = user['reviewCount'] ?? 0;
    user['ecoPoints'] = user['ecoPoints'] ?? 0;

    try {
      // Generate a unique userID
      int userID = await generateUserID();
      user['userID'] = userID;

      // Insert into SQLite
      int sqliteUserID = await db.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert into Firestore with the unique userID
      await FirebaseFirestore.instance.collection('users').add({
        'userID': userID,
        'username': user['username'],
        'email': user['email'],
        'password': user['password'],
        'security_question': user['security_question'],
        'security_answer': user['security_answer'],
        'rating': user['rating'],
        'reviewCount': user['reviewCount'],
        'ecoPoints': user['ecoPoints'],
      });

      return sqliteUserID;
    } catch (e) {
      print('Insert user failed: $e');
      return -1;
    }
  }





  // Sync latest user from Firestore into SQLite
  Future<void> syncUserFromFirestore(String email) async {
    final snapshot =
    await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final userData = snapshot.docs.first.data();

      // Provide fallback values to avoid null in SQLite
      userData['rating'] ??= 0.0;
      userData['reviewCount'] ??= 0;
      userData['ecoPoints'] ??= 0;

      final db = await database;
      await db.insert(
        'users',
        userData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    // Try SQLite first
    final db = await database;
    List<Map<String, dynamic>> local = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (local.isNotEmpty) return local.first;

    // If not found locally, pull from Firestore and sync
    await syncUserFromFirestore(email);
    final fallback = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return fallback.isNotEmpty ? fallback.first : null;
  }

  Future<void> updateUserData(
      String email,
      Map<String, dynamic> updates,
      ) async {
    final db = await database;

    // Update in Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(snapshot.docs.first.id)
          .update(updates);  // Update all fields
    }

    // Then update in SQLite
    await db.update('users', updates, where: 'email = ?', whereArgs: [email]);
  }

  Future<void> updateUserPassword(String email, String newPassword) async {
    await updateUserData(email, {'password': newPassword});
  }

  // Additional helper for syncing all users (e.g., at app launch)
  Future<void> syncAllUsersFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final db = await database;


      for (var doc in snapshot.docs) {
        final userData = doc.data();

        // Use Firestore 'userID' field, not the doc.id
        userData['userID'] ??= 0;
        userData['rating'] ??= 0.0;
        userData['reviewCount'] ??= 0;
        userData['ecoPoints'] ??= 0;

        await db.insert(
          'users',
          userData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('All users synced from Firestore to SQLite.');
    } catch (e) {
      print('Error syncing users from Firestore to SQLite: $e');
    }
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
// Method to update carpool status to 'inactive' in both SQLite and Firestore
  Future<void> updateCarpoolStatusToInactive(String carpoolID) async {
    try {
      // Update Firestore status to 'inactive'
      await FirebaseFirestore.instance
          .collection('carpools')
          .doc(carpoolID)
          .update({'status': 'inactive'});

      // Update SQLite status as well
      final db = await database;
      await db.update(
        'carpools',
        {'status': 'inactive'},
        where: 'firestoreID = ?',
        whereArgs: [carpoolID],
      );
    } catch (e) {
      print('Error updating carpool status: $e');
      throw Exception('Failed to update carpool status');
    }
  }

  // Insert a new carpool into both SQLite and Firestore
  Future<int> insertCarpool(Map<String, dynamic> carpool) async {
    final db = await database;

    try {
      // Insert into Firestore
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('carpools')
          .add({
        'userID': carpool['userID'],
        'pickUpPoint': carpool['pickUpPoint'],
        'dropOffPoint': carpool['dropOffPoint'],
        'date': carpool['date'],
        'time': carpool['time'],
        'availableSeats': carpool['availableSeats'],
        'ridePreference': carpool['ridePreference'],
        'status': carpool['status'],
        'earnings': carpool['earnings'],
        'carPlateNumber': carpool['carPlateNumber'],  // Car plate number
        'carColor': carpool['carColor'],              // Car color
        'carModel': carpool['carModel'],              // Car model
      });

      // After successfully adding to Firestore, insert into SQLite
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
        'carPlateNumber': carpool['carPlateNumber'],  // Car plate number
        'carColor': carpool['carColor'],              // Car color
        'carModel': carpool['carModel'],              // Car model
        'firestoreID': docRef.id,
      };

      // Insert into SQLite
      int carpoolID = await db.insert(
        'carpools',
        carpoolData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return carpoolID; // Return SQLite ID for future references
    } catch (e) {
      print('Failed to insert carpool: $e');
      return -1; // Return error code if Firestore insert fails
    }
  }


  // Insert a new ride into both Firestore and SQLite
  Future<int> insertRide(Map<String, dynamic> ride) async {
    final db = await database;

    // Insert ride into Firestore first
    try {
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('rides')
          .add({
        'carpoolID': ride['carpoolID'],
        'userID': ride['userID'],
        'status': ride['status'],
        'pickupNote': ride['pickupNote'],
        'seat': ride['seat'],
        'musicPreference': ride['musicPreference'],
        'petFriendly': ride['petFriendly'],
        'nonSmoking': ride['nonSmoking'],
      });

      // After successfully adding to Firestore, insert the rest into SQLite with the firestoreID
      Map<String, dynamic> rideData = {
        'carpoolID': ride['carpoolID'],
        'userID': ride['userID'],
        'status': ride['status'],
        'pickupNote': ride['pickupNote'],
        'firestoreID': docRef.id, // Store Firestore ID for future reference
        'seat': ride['seat'],
        'musicPreference': ride['musicPreference'],
        'petFriendly': ride['petFriendly'],
        'nonSmoking': ride['nonSmoking'],
      };

      // Insert into SQLite
      int rideID = await db.insert(
        'rides',
        rideData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return rideID; // Return SQLite ID for future references
    } catch (e) {
      print('Failed to insert ride: $e');
      return -1; // Return error code if Firestore insert fails
    }
  }

  // Get all rides by passenger
  Future<List<Map<String, dynamic>>> getRidesByPassenger(int userID) async {
    final db = await database;
    return await db.query('rides', where: 'userID = ?', whereArgs: [userID]);
  }

  // Get confirmed passengers for a carpool
  Future<List<Map<String, dynamic>>> getConfirmedRidesForCarpool(
      int carpoolID,
      ) async {
    final db = await database;
    return await db.query(
      'rides',
      where: 'carpoolID = ? AND status = ?',
      whereArgs: [carpoolID, 'confirmed'],
    );
  }

  Future<String> requestRide(
      int carpoolID,
      int userID, {
        String pickupNote = '',
      }) async {
    final db = await database;
    try {
      await db.insert('rides', {
        'carpoolID': carpoolID,
        'userID': userID,
        'pickupNote': pickupNote,
        'status': 'requested', // <-- Not Confirmed!
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
      whereArgs: [carpoolID, userID, 'requested'],
    );

    if (existing.isEmpty) return false; // No confirmed ride found

    // Update the ride status to 'canceled'
    await db.update(
      'rides',
      {'status': 'canceled'},
      where: 'carpoolID = ? AND userID = ?',
      whereArgs: [carpoolID, userID],
    );

    // Fetch the Firestore ID for the current ride
    final firestoreID = existing.first['firestoreID'];

    // If a Firestore ID is found, update the ride status to 'canceled' in Firestore
    if (firestoreID != null) {
      try {
        // Update Firestore document with the new status
        await FirebaseFirestore.instance
            .collection('rides')
            .doc(
          firestoreID as String?,
        ) // Access the ride document by Firestore ID
            .update({'status': 'canceled'});

        print('Updated Firestore for ride with Firestore ID: $firestoreID');
      } catch (e) {
        print('Error updating Firestore: $e');
        return false;
      }
    } else {
      print('No Firestore ID found for the ride');
      return false;
    }

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

  // Update ride status (e.g., to confirmed or canceled)
  Future<void> updateRideStatus(int rideID, String status) async {
    final db = await database;
    await db.update(
      'rides',
      {'status': status},
      where: 'rideID = ?',
      whereArgs: [rideID],
    );
  }

  // Fetch all completed or canceled carpools for the user in carpool history
  Future<List<Map<String, dynamic>>> getCarpoolHistory(int userID) async {
    final db = await database;
    return await db.query(
      'carpool_history',  // The name of the table
      where: 'userID = ?',
      whereArgs: [userID], // Only fetch records for the specific user
      orderBy: 'date DESC', // Optional: Order by the date, for example
    );
  }


  // Fetch active carpools for the Registered Carpool page
  Future<List<Map<String, dynamic>>> getCarpools(int userID) async {
    final db = await database;
    return await db.query(
      'carpools',
      where: 'userID = ? AND status = ?',
      whereArgs: [userID, 'active'], // Fetch only active carpools
      orderBy: 'date DESC',
    );
  }


  // Insert carpool history (either completed or canceled)
  Future<void> addCarpoolHistory(
      int carpoolID,
      int userID,
      String status,
      double earnings,
      ) async {
    final db = await database;

    // Retrieve carpool details based on carpoolID from the 'carpools' table
    final carpool = await db.query(
      'carpools',
      where: 'id = ?',
      whereArgs: [carpoolID],
    );

    if (carpool.isNotEmpty) {
      final carpoolData = carpool.first;

      // Insert the completed or canceled carpool into the carpool_history table
      await db.insert('carpool_history', {
        'carpoolID': carpoolID,
        'userID': userID,
        'status': status, // 'completed' or 'canceled'
        'earnings': earnings,
        // Copy details from the carpool table to the history table
        'pickUpPoint': carpoolData['pickUpPoint'],
        'dropOffPoint': carpoolData['dropOffPoint'],
        'date': carpoolData['date'],
        'time': carpoolData['time'],
      });
    }
  }

  // Get list of drivers from completed rides for rating
  // Fetch completed rides for a passenger to rate the driver
  Future<List<Map<String, dynamic>>> getCompletedRidesForPassenger(int userID) async {
    final db = await database;

    // Fetch the completed rides where the user is a passenger
    return await db.rawQuery(
      '''
    SELECT r.rideID, r.carpoolID, r.userID as passengerID, cp.userID as driverID, u.username as driverName, r.status
    FROM rides r
    JOIN carpools cp ON r.carpoolID = cp.id
    JOIN users u ON cp.userID = u.userID
    WHERE r.userID = ? AND r.status = 'completed'
    ''',
      [userID],
    );
  }

  // Submit or update driver's average rating and review count
  // Submit or update driver's average rating and review count
  Future<void> submitDriverRating(int driverID, double newRating, int carpoolID) async {
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

      // Update in SQLite
      await db.update(
        'users',
        {'rating': updatedRating, 'reviewCount': reviewCount + 1},
        where: 'userID = ?',
        whereArgs: [driverID],
      );

      // Update in Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userID', isEqualTo: driverID)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docRef = snapshot.docs.first.reference;
        await docRef.update({
          'rating': updatedRating,
          'reviewCount': reviewCount + 1,
        });
      }

      // Log the ride as completed in carpool_history
      await db.insert('carpool_history', {
        'carpoolID': carpoolID, // Use carpoolID here to track the completed ride
        'userID': driverID,
        'status': 'completed',
        'earnings': 0.0,
      });
    }
  }

  // Fetch data from Firestore and overwrite SQLite
  Future<void> updateSQLiteFromFirestore() async {
    try {
      // Fetch all documents from Firestore
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('carpools').get();

      // Convert Firestore documents into a list of maps
      List<Map<String, dynamic>> allRides =
      snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['firestoreID'] =
            doc.id; // Optional: Store the Firestore document ID in SQLite
        return data;
      }).toList();

      final db = await database;

      for (var ride in allRides) {
        // Check if the record already exists in SQLite based on the Firestore ID
        final existingRide = await db.query(
          'carpools',
          where: 'firestoreID = ?',
          whereArgs: [ride['firestoreID']],
        );

        if (existingRide.isEmpty) {
          // If the record doesn't exist, insert a new one
          await db.insert(
            'carpools',
            ride,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          print('Inserted new carpool with ID: ${ride['firestoreID']}');
        } else {
          // If the record exists, compare the details to avoid unnecessary updates
          final existingRideData = existingRide.first;
          if (!mapEquals(existingRideData, ride)) {
            // If the details have changed, update the existing record
            await db.update(
              'carpools',
              ride,
              where: 'firestoreID = ?',
              whereArgs: [ride['firestoreID']],
            );
            print('Updated carpool with ID: ${ride['firestoreID']}');
          } else {
            print('No change for carpool with ID: ${ride['firestoreID']}');
          }
        }
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
    List<Map<String, dynamic>> filteredRides =
    allRides.where((ride) {
      bool locationMatch =
          ride['pickUpPoint'] == fromLocation &&
              ride['dropOffPoint'] == toLocation;

      bool preferenceMatch = true;
      if (musicPreference) {
        preferenceMatch &=
            ride['ridePreference']?.toString().contains('Music') ?? false;
      }
      if (petFriendly) {
        preferenceMatch &=
            ride['ridePreference']?.toString().contains('Pet') ?? false;
      }
      if (nonSmoking) {
        preferenceMatch &=
            ride['ridePreference']?.toString().contains('Non-Smoking') ??
                false;
      }

      bool seatAvailable = (ride['availableSeats'] ?? 0) >= seatCount;

      return locationMatch && preferenceMatch && seatAvailable;
    }).toList();

    return filteredRides;
  }

  Future<void> syncRidesFromFirestoreToSQLite() async {
    try {
      // Fetch all ride documents from Firestore
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('rides').get();

      // Convert Firestore documents into a list of maps
      List<Map<String, dynamic>> allRides =
      snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['firestoreID'] =
            doc.id; // Store the Firestore document ID in SQLite
        return data;
      }).toList();

      final db = await database;

      // Loop through all the rides from Firestore
      for (var ride in allRides) {
        // Check if the ride already exists in SQLite based on the Firestore ID
        final existingRide = await db.query(
          'rides',
          where: 'firestoreID = ?',
          whereArgs: [ride['firestoreID']],
        );

        if (existingRide.isEmpty) {
          // If the ride doesn't exist, insert it
          await db.insert(
            'rides',
            ride,
            conflictAlgorithm:
            ConflictAlgorithm
                .replace, // In case of conflict, replace the data
          );
          print('Inserted new ride with Firestore ID: ${ride['firestoreID']}');
        } else {
          // If the ride exists, compare the data
          final existingRideData = existingRide.first;
          if (!mapEquals(existingRideData, ride)) {
            // If the data is different, update the existing record
            await db.update(
              'rides',
              ride,
              where: 'firestoreID = ?',
              whereArgs: [ride['firestoreID']],
            );
            print('Updated ride with Firestore ID: ${ride['firestoreID']}');
          } else {
            print(
              'No changes for ride with Firestore ID: ${ride['firestoreID']}',
            );
          }
        }
      }

      print('SQLite synced with Firestore data.');
    } catch (e) {
      print('Error syncing rides from Firestore to SQLite: $e');
    }
  }

  // Update the ride status in both SQLite and Firestore
  Future<void> confirmOrRejectRide(
      int rideID,
      String status,
      int seatsToReduce,
      ) async {
    final db = await database;

    // First, update the ride status in SQLite
    await db.update(
      'rides',
      {'status': status},
      where: 'rideID = ?',
      whereArgs: [rideID],
    );

    // Then, update the ride status in Firestore
    try {
      // Fetch the ride from SQLite to get the carpoolID and userID
      final ride = await db.query(
        'rides',
        where: 'rideID = ?',
        whereArgs: [rideID],
      );

      if (ride.isNotEmpty) {
        final carpoolID = ride.first['carpoolID'];
        final userID = ride.first['userID'];

        // Get the corresponding ride document from Firestore
        final rideDocRef = FirebaseFirestore.instance
            .collection('rides')
            .doc(ride.first['firestoreID'] as String?);

        // Update the status of the ride in Firestore (confirm or reject)
        await rideDocRef.update({
          'status': status, // 'confirmed' or 'rejected'
        });

        // Additional logic (e.g., if confirmed, update available seats in carpool)
        if (status == 'confirmed') {
          // Reduce the available seats for the carpool by seatsToReduce
          await _updateCarpoolAvailableSeats(
            carpoolID as int,
            seatsToReduce,
            status,
          );
        } else if (status == 'completed') {
          await _updateCarpoolAvailableSeats(
            carpoolID as int,
            seatsToReduce,
            status,
          );
        }
      }
    } catch (e) {
      print('Failed to update ride status in Firestore: $e');
    }
  }

  // Reduce available seats in the carpool when a ride is confirmed
  Future<void> _updateCarpoolAvailableSeats(
      int carpoolID,
      int seatsToReduce,
      String status,
      ) async {
    final db = await database;
    final carpool = await db.query(
      'carpools',
      where: 'id = ?',
      whereArgs: [carpoolID],
    );

    if (carpool.isNotEmpty) {
      int availableSeats = (carpool.first['availableSeats'] as int?) ?? 0;

      if (status == 'completed') {
        // If the status is 'completed', add the seats back
        availableSeats += seatsToReduce;
      } else {
        // Otherwise, reduce the available seats
        if (availableSeats >= seatsToReduce) {
          availableSeats -= seatsToReduce;
        } else {
          print("Not enough available seats to reduce by $seatsToReduce.");
          return;
        }
      }

      // Update the available seats in SQLite
      await db.update(
        'carpools',
        {'availableSeats': availableSeats},
        where: 'id = ?',
        whereArgs: [carpoolID],
      );
      // Update the available seats in Firestore as well
      try {
        // Get the carpool document reference from Firestore
        final carpoolDocRef = FirebaseFirestore.instance
            .collection('carpools')
            .doc(carpool.first['firestoreID'] as String?);

        // Update the availableSeats field in Firestore
        await carpoolDocRef.update({
          'availableSeats': availableSeats - seatsToReduce,
        });

        print("Successfully updated available seats in Firestore.");
      } catch (e) {
        print("Failed to update available seats in Firestore: $e");
      }
    } else {
      print("Not enough available seats to reduce by $seatsToReduce.");
    }
  }

  Future<Map<String, dynamic>?> getCarpoolByID(int carpoolID) async {
    final db = await database;
    final result = await db.query(
      'carpools',
      where: 'id = ?',
      whereArgs: [carpoolID],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<String> checkRideStatus(int rideID, int carpoolID, int userID) async {
    final db = await database;

    // Query the rides table for the status based on carpoolID and userID
    final result = await db.query(
      'rides',
      where: 'rideID = ? AND carpoolID = ? AND userID = ?',
      whereArgs: [rideID, carpoolID, userID],
      limit: 1,
    );

    if (result.isNotEmpty) {
      // Check the ride status
      String status = result.first['status'] as String;

      // Return the status: "confirmed", "rejected", "pending", etc.
      return status;
    }

    // If no record is found, return an empty status (or "not found")
    return 'not_found';
  }

  // Fetch user details by userID
  Future<Map<String, dynamic>?> getUserByID(int userID) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'userID = ?',
      whereArgs: [userID],
    );
    if (result.isNotEmpty) {
      return result.first; // Returning the first user
    }
    return null; // No user found
  }

  // Method to fetch rides for a specific carpoolID
  Future<List<Map<String, dynamic>>> getRidesByCarpoolID(int carpoolID) async {
    final db = await database;
    // Query the 'rides' table where carpoolID matches the provided carpoolID
    final result = await db.query(
      'rides',
      where: 'carpoolID = ?',
      whereArgs: [carpoolID],
    );

    return result; // Return the list of rides (empty list if none found)
  }

  // Fetch ride details from the 'rides' table based on rideID
  Future<Map<String, dynamic>?> getRideByID(int rideID) async {
    final db = await database;
    final result = await db.query(
      'rides',
      where: 'rideID = ?',
      whereArgs: [rideID],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
  Future<void> syncCarpoolsFromFirestoreToSQLite() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('carpools').get();
      final db = await database;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['firestoreID'] = doc.id;  // Store Firestore document ID in SQLite

        final existingCarpool = await db.query(
          'carpools',
          where: 'firestoreID = ?',
          whereArgs: [data['firestoreID']],
        );

        if (existingCarpool.isEmpty) {
          await db.insert('carpools', data, conflictAlgorithm: ConflictAlgorithm.replace);
        } else {
          await db.update('carpools', data, where: 'firestoreID = ?', whereArgs: [data['firestoreID']]);
        }
      }
      print('Carpools data synced from Firestore to SQLite.');
    } catch (e) {
      print('Error syncing carpools: $e');
    }
  }


  Future<bool> hasOngoingRide(int userID) async {
    final db = await database;

    final result = await db.query(
      'rides',
      where: 'userID = ? AND status != ?',
      whereArgs: [userID, 'completed'],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<void> updateUserEcoPoints(int userID, int ecoPoints) async {
    final db = await database;

    try {
      await db.update(
        'users',
        {'ecoPoints': ecoPoints},
        where: 'userID = ?',
        whereArgs: [userID],
      );

      final user = await db.query(
        'users',
        where: 'userID = ?',
        whereArgs: [userID],
      );

      if (user.isNotEmpty) {
        final firestoreID = user.first['firestoreID'] as String?;

        if (firestoreID == null) {
          print('Firestore ID is missing for user $userID');
          return;
        }

        final userDocRef = FirebaseFirestore.instance.collection('users').doc(firestoreID);

        await userDocRef.update({
          'ecoPoints': ecoPoints,
        });

        print('User ecoPoints updated successfully in Firestore');
      }
    } catch (e) {
      print('Error updating ecoPoints: $e');
    }
  }


  Future<int> insertVoucher(Map<String, dynamic> voucher) async {
    final db = await database;
    try {
      // Insert to Firestore
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('vouchers')
          .add(voucher);

      // Add Firestore ID to local map
      voucher['firestoreID'] = docRef.id;

      // Insert into SQLite
      return await db.insert('vouchers', voucher);
    } catch (e) {
      print('Insert voucher failed: $e');
      return -1;
    }
  }


  Future<int> updateVoucher(int id, Map<String, dynamic> voucher) async {
    final db = await database;
    try {
      if (voucher['firestoreID'] != null) {
        await FirebaseFirestore.instance
            .collection('vouchers')
            .doc(voucher['firestoreID'])
            .update({
          'redeemedBy': voucher['redeemedBy'],
          'name': voucher['name'],
          'description': voucher['description'],
          'startDate': voucher['startDate'],
          'endDate': voucher['endDate'],
          'ecoPointsRequired': voucher['ecoPointsRequired'],
        });
      }

      return await db.update(
        'vouchers',
        voucher,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Update voucher failed: $e');
      return -1;
    }
  }



  Future<int> deleteVoucher(int id, String firestoreID) async {
    final db = await database;
    try {
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('vouchers')
          .doc(firestoreID)
          .delete();

      // Delete from SQLite
      return await db.delete('vouchers', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Delete voucher failed: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllVouchers() async {
    final db = await database;
    return await db.query('vouchers');
  }
  Future<void> addCarpoolHistoryToFirestore(
      String firestoreCarpoolID,
      int userID,
      String status,
      double earnings,
      ) async {
    try {
      // Step 1: Fetch carpool details from Firestore using the document ID
      final carpoolDoc = await FirebaseFirestore.instance
          .collection('carpools')
          .doc(firestoreCarpoolID)
          .get();

      if (!carpoolDoc.exists) {
        throw Exception('Carpool not found in Firestore.');
      }

      final data = carpoolDoc.data()!;
      final pickUpPoint = data['pickUpPoint'] ?? 'Unknown';
      final dropOffPoint = data['dropOffPoint'] ?? 'Unknown';
      final date = data['date'] ?? DateTime.now().toIso8601String();
      final time = data['time'] ?? DateTime.now().toIso8601String();

      // Step 2: Compose full history entry
      final historyData = {
        'carpoolID': firestoreCarpoolID,
        'userID': userID,
        'status': status,
        'earnings': earnings,
        'pickUpPoint': pickUpPoint,
        'dropOffPoint': dropOffPoint,
        'date': date,
        'time': time,
      };

      // Step 3: Insert into Firestore carpool_history collection
      await FirebaseFirestore.instance
          .collection('carpool_history')
          .add(historyData);

      print('✅ Carpool history stored in Firestore');
    } catch (e) {
      print('❌ Error storing carpool history in Firestore: $e');
      throw Exception('Failed to add carpool history');
    }
  }

  Future<void> syncCarpoolHistoryFromFirestoreToSQLite(int userID) async {
    try {
      // Fetch data from Firestore collection 'carpool_history' for a specific user
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('carpool_history')
          .where('userID', isEqualTo: userID) // Filter by userID
          .get();
      final db = await database;

      // Loop through each Firestore document
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Add the Firestore document ID to the data
        data['firestoreID'] = doc.id;

        // Check if the history entry already exists in SQLite using Firestore ID
        final existingHistory = await db.query(
          'carpool_history',
          where: 'firestoreID = ?',
          whereArgs: [data['firestoreID']],
        );

        if (existingHistory.isEmpty) {
          // If the entry doesn't exist, insert it into SQLite
          await db.insert(
            'carpool_history',
            data,
            conflictAlgorithm: ConflictAlgorithm.replace,  // Replace existing data if conflict
          );
          print('Inserted carpool history: ${doc.id}');
        } else {
          // If the entry already exists, update it in SQLite
          await db.update(
            'carpool_history',
            data,
            where: 'firestoreID = ?',
            whereArgs: [data['firestoreID']],
          );
          print('Updated carpool history: ${doc.id}');
        }
      }

      print('✅ Carpool history synced from Firestore to SQLite.');
    } catch (e) {
      print('❌ Error syncing carpool history from Firestore: $e');
    }
  }



  Future<Map<String, dynamic>?> getCarpoolByFirestoreID(String firestoreID) async {
    final db = await database;
    final result = await db.query(
      'carpools',
      where: 'firestoreID = ?',
      whereArgs: [firestoreID],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }


}