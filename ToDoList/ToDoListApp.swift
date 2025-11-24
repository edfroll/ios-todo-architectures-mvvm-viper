//
//  ToDoListApp.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//

import SwiftUI

@main
struct ToDoListApp: App {
    var body: some Scene {
        WindowGroup {
            TaskMainRouter.build()
        }
    }
}
