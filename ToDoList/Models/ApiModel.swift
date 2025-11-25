//
//  ApiModel.swift
//  ToDoList
//
//  Created by Эдвард on 25.11.2025.
//
import Foundation

struct ApiModel: Identifiable, Codable {
    
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
    
}

struct ApiResponse: Codable {
    let todos: [ApiModel]
    
}
