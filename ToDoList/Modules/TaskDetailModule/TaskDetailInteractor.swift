//
//  TaskDetailInteractor.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation
import CoreData

final class TaskDetailInteractor: TaskDetailInteractorProtocol {
    
    // MARK: Properties
    weak var presenter: TaskDetailPresenterProtocol?
    
    private let id: UUID
    private var task: DataTask?
    let container: NSPersistentContainer
    
    private lazy var request = {
        let request = NSFetchRequest<DataTask>(entityName: "DataTask")
        request.predicate = NSPredicate(format: "id == %@", self.id as CVarArg)
        request.fetchLimit = 1
        return request
    }()
    
    init(taskId: UUID, container: NSPersistentContainer) {
        self.id = taskId
        self.container = container
    }
    
    // MARK: Fetch
    /// Главный метод этого интерактора. Без него остальные его методы - не сработают
    func fetchTask() {
        do {
            if let task = try container.viewContext.fetch(request).first { // простой fetch - background thread не нужен
                self.task = task // добавляем кеш
                presenter?.didFetchTask(task) // главный поток
            }
            
        } catch {
            print("Ошибка загрузки задачи: \(error.localizedDescription)")
        }
    }
    
    // MARK: Update
    func updateTask(_ newTitle: String?, _ newBody: String?) {
        guard let task = task else { return }
        
        if let title = newTitle {
            task.title = title
        }
        if let body = newBody {
            task.body = body
        }
        
        task.date = Date.now
        presenter?.didChangeTask()
        
    }
    
    // MARK: Delete
    func deleteTask() {
        guard let task = task else { return }
        container.viewContext.delete(task)
        presenter?.didChangeTask()
    }
    
}
