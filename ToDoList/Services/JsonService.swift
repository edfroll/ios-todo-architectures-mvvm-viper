//
//  JsonService.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
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

class JsonService {
    func fetchTasks() async throws -> [ApiModel] {
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ApiResponse.self, from: data)
        return response.todos
    }
}
