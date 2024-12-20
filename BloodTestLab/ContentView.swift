//
//  ContentView.swift
//  BloodTestLab
//
//  Created by sarmad on 12/14/24.
//

import SwiftUI
import SQLite3


struct ContentView: View {
    var body: some View {
        Text("Fetching Users")
            .padding()
            .onAppear {
                let dbHelper = SQLiteHelper(databaseName: "BloodTestLab.sqlite")

                // Fetch users from the database
                let users = dbHelper.fetchUsers()
                for user in users {
                    print("ID: \(user.id), Name: \(user.name), Email: \(user.email)")
                }

                dbHelper.closeDatabase()
            }
    }
}


    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }

