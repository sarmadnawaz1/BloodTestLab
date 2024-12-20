import Foundation
import SQLite3

class SQLiteHelper: ObservableObject {
    private var db: OpaquePointer?
    private let databaseName: String
    
    
    
    
    init(databaseName: String) {
        self.databaseName = databaseName
        openDatabase()
        createUserTables()
        addUserIdColumn()
        printTableSchema(tableName: "Appointments")
        
        
        
        
        
    }
    
    deinit {
        closeDatabase()
    }
    
    private func openDatabase() {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let databaseURL = documentDirectory.appendingPathComponent(databaseName)
        
        if sqlite3_open(databaseURL.path, &db) != SQLITE_OK {
            print("Failed to open database.")
        }
    }
    
    func closeDatabase() {
        if sqlite3_close(db) != SQLITE_OK {
            print("Failed to close database.")
        }
    }
    
    func printTableSchema(tableName: String) {
        let query = "PRAGMA table_info(\(tableName));"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            print("Table schema for \(tableName):")
            while sqlite3_step(stmt) == SQLITE_ROW {
                let columnName = String(cString: sqlite3_column_text(stmt, 1))
                let columnType = String(cString: sqlite3_column_text(stmt, 2))
                print("Column: \(columnName), Type: \(columnType)")
            }
        } else {
            print("Failed to fetch table schema: \(String(cString: sqlite3_errmsg(db)!))")
        }
        sqlite3_finalize(stmt)
    }
    
    private func executeQuery(_ query: String) {
        var errorMessage: UnsafeMutablePointer<Int8>? = nil
        if sqlite3_exec(db, query, nil, nil, &errorMessage) != SQLITE_OK {
            if let errorMessage = errorMessage {
                print("Error executing query: \(String(cString: errorMessage))")
            }
        }
    }
    
    private func createUserTables() {
        let createUsersTable = """
        CREATE TABLE IF NOT EXISTS Users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
        );
        """
        let createAppointmentsTable = """
            CREATE TABLE IF NOT EXISTS Appointments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                doctorName TEXT NOT NULL,
                testTypes TEXT NOT NULL, -- Comma-separated list of test types
                appointmentDate TEXT NOT NULL,
                timeSlot TEXT NOT NULL,
                address TEXT NOT NULL
            );
            """
        executeQuery(createUsersTable)
        executeQuery(createAppointmentsTable)
    }
    
    private func migrateAppointmentsTable() {
        let addDoctorName = "ALTER TABLE Appointments ADD COLUMN doctorName TEXT NOT NULL DEFAULT '';"
        let addTestTypes = "ALTER TABLE Appointments ADD COLUMN testTypes TEXT NOT NULL DEFAULT '';"
        let addAppointmentDate = "ALTER TABLE Appointments ADD COLUMN appointmentDate TEXT NOT NULL DEFAULT '';"
        let addTimeSlot = "ALTER TABLE Appointments ADD COLUMN timeSlot TEXT NOT NULL DEFAULT '';"
        let addAddress = "ALTER TABLE Appointments ADD COLUMN address TEXT NOT NULL DEFAULT '';"
        
        executeQuery(addDoctorName)
        executeQuery(addTestTypes)
        executeQuery(addAppointmentDate)
        executeQuery(addTimeSlot)
        executeQuery(addAddress)
    }
    func addUserIdColumn() {
        let alterTableQuery = "ALTER TABLE Appointments ADD COLUMN userId INTEGER;"
        executeQuery(alterTableQuery)
        print("Added userId column to Appointments table.")
    }
    
    
    private func resetAppointmentsTable() {
        let dropTableQuery = "DROP TABLE IF EXISTS Appointments;"
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Appointments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            doctorName TEXT NOT NULL,
            testTypes TEXT NOT NULL, -- Comma-separated list of test types
            appointmentDate TEXT NOT NULL,
            timeSlot TEXT NOT NULL,
            address TEXT NOT NULL
        );
        """
        executeQuery(dropTableQuery)
        executeQuery(createTableQuery)
        print("Appointments table reset successfully.")
    }
    
    
    
    func fetchUsers() -> [User] {
        let query = "SELECT id, name, email FROM Users;"
        var stmt: OpaquePointer?
        var users: [User] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = sqlite3_column_int(stmt, 0)
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let email = String(cString: sqlite3_column_text(stmt, 2))
                users.append(User(id: Int(id), name: name, email: email))
            }
        }
        sqlite3_finalize(stmt)
        return users
    }
    
    
    func verifyUserCredentials(email: String, password: String) -> Int? {
        let query = "SELECT id FROM Users WHERE email = ? AND password = ?;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, email, -1, nil)
            sqlite3_bind_text(stmt, 2, password, -1, nil)
            
            if sqlite3_step(stmt) == SQLITE_ROW {
                let userId = sqlite3_column_int(stmt, 0) // Get the user ID
                sqlite3_finalize(stmt)
                return Int(userId) // Return user ID if credentials are correct
            }
        }
        
        sqlite3_finalize(stmt)
        return nil // Return nil if no match is found
    }
    
    
    
    func updateAppointment(appointmentId: Int, newDate: String, newTestType: String) -> Bool {
        let query = "UPDATE Appointments SET date = ?, testType = ? WHERE id = ?;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, newDate, -1, nil)
            sqlite3_bind_text(stmt, 2, newTestType, -1, nil)
            sqlite3_bind_int(stmt, 3, Int32(appointmentId))
            
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
                return true
            }
        }
        sqlite3_finalize(stmt)
        return false
    }
    
    
    func getResults(userId: Int) -> [(testType: String, result: String)] {
        let query = "SELECT testType, result FROM Results WHERE userId = ?;"
        var stmt: OpaquePointer?
        var results: [(testType: String, result: String)] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(userId))
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                let testType = String(cString: sqlite3_column_text(stmt, 0))
                let result = String(cString: sqlite3_column_text(stmt, 1))
                results.append((testType, result))
            }
        }
        sqlite3_finalize(stmt)
        return results
    }
    
    func login(email: String, password: String) -> Bool {
        let query = "SELECT id, name, email FROM Users WHERE email = ? AND password = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, email, -1, nil)
            sqlite3_bind_text(statement, 2, password, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let email = String(cString: sqlite3_column_text(statement, 2))
                
                
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    
    func insertAppointment(
        userId: Int,
        doctorName: String,
        testTypes: [String],
        appointmentDate: Date,
        timeSlot: String,
        address: String
    ) -> Bool {
        let query = """
           INSERT INTO Appointments (userId, doctorName, testTypes, appointmentDate, timeSlot, address)
           VALUES (?, ?, ?, ?, ?, ?);
           """
        var statement: OpaquePointer?
        
       
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(userId)) // Bind userId to the first placeholder
                sqlite3_bind_text(statement, 2, doctorName, -1, nil) // Bind doctorName to the second
                sqlite3_bind_text(statement, 3, testTypes.joined(separator: ","), -1, nil) // Bind testTypes
                sqlite3_bind_text(statement, 4, formatDate(appointmentDate), -1, nil) // Bind appointmentDate
                sqlite3_bind_text(statement, 5, timeSlot, -1, nil) // Bind timeSlot
                sqlite3_bind_text(statement, 6, address, -1, nil) // Bind address
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    sqlite3_finalize(statement)
                    return true
                } else {
                    print("Failed to insert appointment: \(String(cString: sqlite3_errmsg(db)!))")
                }
            } else {
                print("Failed to prepare insert statement: \(String(cString: sqlite3_errmsg(db)!))")
            }
            
            sqlite3_finalize(statement)
            return false
        }
        
        func getAppointmentsForUser(userId: Int) -> [Appointment] {
            let query = "SELECT id, doctorName, testTypes, appointmentDate, timeSlot, address FROM Appointments WHERE userId = ?;"
            var stmt: OpaquePointer?
            var appointments: [Appointment] = []
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(userId))
                
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(stmt, 0))
                    let doctorName = String(cString: sqlite3_column_text(stmt, 1))
                    let testTypes = String(cString: sqlite3_column_text(stmt, 2)).components(separatedBy: ",")
                    let appointmentDate = String(cString: sqlite3_column_text(stmt, 3))
                    let timeSlot = String(cString: sqlite3_column_text(stmt, 4))
                    let address = String(cString: sqlite3_column_text(stmt, 5))
                    
                    let appointment = Appointment(
                        id: id,
                        doctorName: doctorName,
                        testTypes: testTypes,
                        appointmentDate: appointmentDate,
                        timeSlot: timeSlot,
                        address: address
                    )
                    appointments.append(appointment)
                }
            } else {
                print("Failed to fetch appointments: \(String(cString: sqlite3_errmsg(db)!))")
            }
            
            sqlite3_finalize(stmt)
            return appointments
        }
        
        
        func fetchAppointments() -> [Appointment] {
            let query = "SELECT id, doctorName, testTypes, appointmentDate, timeSlot, address FROM Appointments;"
            var statement: OpaquePointer?
            var appointments: [Appointment] = []
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(statement, 0))
                    let doctorName = String(cString: sqlite3_column_text(statement, 1))
                    let testTypes = String(cString: sqlite3_column_text(statement, 2)).components(separatedBy: ",")
                    let appointmentDate = String(cString: sqlite3_column_text(statement, 3))
                    let timeSlot = String(cString: sqlite3_column_text(statement, 4))
                    let address = String(cString: sqlite3_column_text(statement, 5))
                    
                    let appointment = Appointment(
                        id: id,
                        doctorName: doctorName,
                        testTypes: testTypes,
                        appointmentDate: appointmentDate,
                        timeSlot: timeSlot,
                        address: address
                    )
                    appointments.append(appointment)
                    
                    
                }
            } else {
                print("Failed to fetch appointments: \(String(cString: sqlite3_errmsg(db)!))")
            }
            
            sqlite3_finalize(statement)
            return appointments
        }
        
        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        
        
        
        func hasAppointment(userId: Int) -> Bool {
            let query = "SELECT COUNT(*) FROM Appointments WHERE userId = ?;"
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(userId))
                
                if sqlite3_step(stmt) == SQLITE_ROW {
                    let count = sqlite3_column_int(stmt, 0)
                    sqlite3_finalize(stmt)
                    return count > 0
                }
            }
            sqlite3_finalize(stmt)
            return false
        }
        
        func bookAppointment(userId: Int, testType: String, date: String) -> Bool {
            let query = "INSERT INTO Appointments (userId, testType, date) VALUES (?, ?, ?);"
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(userId))
                sqlite3_bind_text(stmt, 2, testType, -1, nil)
                sqlite3_bind_text(stmt, 3, date, -1, nil)
                
                if sqlite3_step(stmt) == SQLITE_DONE {
                    sqlite3_finalize(stmt)
                    return true
                }
            }
            sqlite3_finalize(stmt)
            return false
        }
        
        
        func getAppointmentForUser(userId: Int) -> (id: Int, date: String, testType: String)? {
            let query = "SELECT id, date, testType FROM Appointments WHERE userId = ?;"
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(userId))
                
                if sqlite3_step(stmt) == SQLITE_ROW {
                    let id = sqlite3_column_int(stmt, 0)
                    let date = String(cString: sqlite3_column_text(stmt, 1))
                    let testType = String(cString: sqlite3_column_text(stmt, 2))
                    sqlite3_finalize(stmt)
                    return (id: Int(id), date: date, testType: testType)
                }
            }
            sqlite3_finalize(stmt)
            return nil
        }
        
        
    }
    
    extension SQLiteHelper {
        func addAppointment(userId: Int, appointmentDate: String, testType: String) -> Bool {
            let query = "INSERT INTO Appointments (userId, date, testType) VALUES (?, ?, ?);"
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(userId))
                sqlite3_bind_text(stmt, 2, appointmentDate, -1, nil)
                sqlite3_bind_text(stmt, 3, testType, -1, nil)
                
                if sqlite3_step(stmt) == SQLITE_DONE {
                    sqlite3_finalize(stmt)
                    return true
                }
            }
            sqlite3_finalize(stmt)
            return false
        }
        
        
        
    }
    
    extension SQLiteHelper {
        func cancelAppointment(appointmentId: Int) -> Bool {
            let query = "DELETE FROM Appointments WHERE id = ?;"
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(appointmentId))
                
                if sqlite3_step(stmt) == SQLITE_DONE {
                    sqlite3_finalize(stmt)
                    return true
                }
            }
            sqlite3_finalize(stmt)
            return false
        }
    }
    
    
    
    extension SQLiteHelper {
        func getAppointment(userId: Int) -> (id: Int, date: String, testType: String)? {
            let query = "SELECT id, date, testType FROM Appointments WHERE userId = ?;"
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(userId))
                
                if sqlite3_step(stmt) == SQLITE_ROW {
                    let id = sqlite3_column_int(stmt, 0)
                    let date = String(cString: sqlite3_column_text(stmt, 1))
                    let testType = String(cString: sqlite3_column_text(stmt, 2))
                    sqlite3_finalize(stmt)
                    return (id: Int(id), date: date, testType: testType)  // Ensure all values are returned
                }
            }
            sqlite3_finalize(stmt)
            return nil  // Return nil if no appointment is found
        }
    }
    
    
    
    extension SQLiteHelper {
        func insertUser(name: String, email: String, password: String) -> Int? {
            let query = "INSERT INTO Users (name, email, password) VALUES (?, ?, ?);"
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, name, -1, nil)
                sqlite3_bind_text(stmt, 2, email, -1, nil)
                sqlite3_bind_text(stmt, 3, password, -1, nil)
                
                if sqlite3_step(stmt) == SQLITE_DONE {
                    let userId = sqlite3_last_insert_rowid(db)
                    sqlite3_finalize(stmt)
                    return Int(userId) // Return the generated userId
                } else {
                    print("Failed to insert user: \(String(cString: sqlite3_errmsg(db)!))")
                }
            } else {
                print("Failed to prepare user insert statement: \(String(cString: sqlite3_errmsg(db)!))")
            }
            
            sqlite3_finalize(stmt)
            return nil // Return nil if insertion failed
        }
        
    }
    
    
    
    extension SQLiteHelper {
        func doesUserExist(email: String) -> Bool {
            let query = "SELECT COUNT(*) FROM Users WHERE email = ?;"
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, email, -1, nil)
                
                if sqlite3_step(stmt) == SQLITE_ROW {
                    let count = sqlite3_column_int(stmt, 0)
                    sqlite3_finalize(stmt)
                    return count > 0 // Return true if count > 0 (user exists)
                }
            }
            sqlite3_finalize(stmt)
            return false
        }
        
        
    }
    
    extension SQLiteHelper {
        func insertSimplifiedAppointment(
            doctorName: String,
            testTypes: [String],
            appointmentDate: Date,
            timeSlot: String,
            address: String
        ) -> Bool {
            let query = """
        INSERT INTO Appointments (doctorName, testTypes, appointmentDate, timeSlot, address)
        VALUES (?, ?, ?, ?, ?);
        """
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                
                print("mubarak ho db")
                sqlite3_bind_text(statement, 1, doctorName, -1, nil)
                sqlite3_bind_text(statement, 2, testTypes.joined(separator: ","), -1, nil)
                sqlite3_bind_text(statement, 3, appointmentDate.description, -1, nil)
                sqlite3_bind_text(statement, 4, timeSlot, -1, nil)
                sqlite3_bind_text(statement, 5, address, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    sqlite3_finalize(statement)
                    return true
                }
            }
            else {
                print("Bhai nahi hoi db")
            }
            
            sqlite3_finalize(statement)
            return false
        }
    }
    
    
    
    
    
    
    struct User {
        let id: Int
        let name: String
        let email: String
    }
    
    struct Appointment {
        let id: Int
        let doctorName: String
        let testTypes: [String]
        let appointmentDate: String
        let timeSlot: String
        let address: String
    }
    
