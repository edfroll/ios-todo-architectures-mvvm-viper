//
//  TaskDetailInteractor.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation
import CoreData

// Бизнес логика для работы с одной задачей
class TaskDetailInteractor: TaskDetailInteractorProtocol {
    
    weak var presenter: TaskDetailPresenterProtocol? // решение проблемы retain cycle при сборке
    private let id: UUID
    
    private var task: DataTask?
    
    // ✅ Используем общий контейнер
    let container: NSPersistentContainer// = CoreDataManager.shared.container
    
    init(taskId: UUID, container: NSPersistentContainer) {
        self.id = taskId
        self.container = container
    }
    
    // MARK: - Fetch task
    /// Главный метод этого интерактора. Без него остальные его методы - не сработают
    func fetchTask() {
        do {
            
            if let task = try container.viewContext.fetch(request).first { // может завернуть в DispatchQueue.global.async ?
                self.task = task
                DispatchQueue.main.async { [weak self] in
                    self?.presenter?.didFetchTask(task)
                }
            }
            
        } catch {
            print("❌ Ошибка загрузки задачи: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update task
    func updateTask(_ newTitle: String?, _ newBody: String?) {
        guard let task = task else { return }
        
        if let title = newTitle {
            task.title = title
        }
        if let body = newBody {
            task.body = body
        }
        
        task.date = Date.now
        print("Задача обновлена.")
        presenter?.didChangeTask() // ✅ Единый сигнал обновления
        
    }
    
    func deleteTask() {
        guard let task = task else { return }
        container.viewContext.delete(task)
        print("Задача удалена.")
        presenter?.didChangeTask() // ✅ Единый сигнал обновления
    }
    
    private lazy var request = {
        let request = NSFetchRequest<DataTask>(entityName: "DataTask")
        request.predicate = NSPredicate(format: "id == %@", self.id as CVarArg)
        request.fetchLimit = 1
        return request
    }()
    
    
}
