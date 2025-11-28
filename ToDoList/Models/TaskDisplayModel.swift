//
//  TaskDisplayModel.swift
//  ToDoList
//
//  Created by Эдвард on 27.11.2025.
//
import Foundation

struct TaskDisplayModel: Identifiable, Equatable, Hashable {
    var id: UUID
    var title: String
    var body: String
    var dateString: String
    var isCompleted: Bool
}
