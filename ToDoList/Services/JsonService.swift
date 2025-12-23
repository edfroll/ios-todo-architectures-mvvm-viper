//
//  JsonService.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//

import Foundation

// MARK: - API Models
struct ApiModel: Identifiable, Codable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
}

struct ApiResponse: Codable {
    let todos: [ApiModel]
}

// MARK: - Custom Errors
enum JsonServiceError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - JsonService
final class JsonService {

    func fetchTasks(completion: @escaping (Result<[ApiModel], JsonServiceError>) -> Void) {
        
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            DispatchQueue.main.async {
                completion(.failure(.invalidURL))
            }
            return
        }
        
        // Создаем data task
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            // Обработка сетевой ошибки
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            // Проверка наличия данных
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            // Декодирование JSON
            do {
                let response = try JSONDecoder().decode(ApiResponse.self, from: data)
                
                // Успех - возвращаем на главном потоке
                DispatchQueue.main.async {
                    completion(.success(response.todos))
                }
                
            } catch {
                // Ошибка декодирования
                DispatchQueue.main.async {
                    completion(.failure(.decodingFailed(error)))
                }
            }
        }
        
        task.resume()
    }
}
