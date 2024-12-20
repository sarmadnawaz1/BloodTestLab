//
//  BloodTestLabApp.swift
//  BloodTestLab
//
//  Created by sarmad on 12/14/24.
//

import SwiftUI


@main
struct BloodTestLabApp: App {
    
    
    
    var body: some Scene {
        WindowGroup {
            // Here, we reference the LoginView, which is your app's main view
            LoginView(dbHelper: SQLiteHelper(databaseName: "BloodTestLab.sqlite"))
        }
    }
}
