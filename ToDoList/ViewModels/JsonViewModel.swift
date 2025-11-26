//
//  JsonViewModel.swift
//  ToDoList
//
//  Created by Эдвард on 22.09.2025.

import Foundation

class JsonViewModel {
    
    func fetchTasks() async throws -> [ApiModel] {
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ApiResponse.self, from: data)
        return response.todos
    }
}
