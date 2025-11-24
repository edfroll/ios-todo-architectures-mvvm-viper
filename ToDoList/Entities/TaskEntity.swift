//
//  TaskEntity.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation

struct TaskDisplayModel: Identifiable, Equatable {
    var id: UUID
    var title: String
    var body: String
    var dateString: String
    var isCompleted: Bool
}
