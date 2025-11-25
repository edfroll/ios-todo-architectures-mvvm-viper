//
//  JsonViewModel.swift
//  ToDoList
//
//  Created by Эдвард on 22.09.2025.
//
import Foundation

class JsonViewModel: ObservableObject {
    
    @Published var tasks: [ApiModel] = []

    init() {
        fetchTasks()
    }
    
    func fetchTasks() {
        guard let url = URL(string: "https://dummyjson.com/todos") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            
            guard let self = self else { return }
            
            if let error = error {
                print("Ошибка загрузки данных: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Нет данных")
                return
            }
            
            
            do {
                let response = try JSONDecoder().decode(ApiResponse.self, from: data)
                DispatchQueue.main.async {
                    self.tasks = response.todos
                }
            } catch {
                print("Ошибка парсинга: \(error.localizedDescription)")
            }
        
        }
        task.resume()
    }
}




