//
//  TaskMainInteractor.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation
import CoreData

// MARK: - Task Main Interactor
// Вся бизнес-логика, работа с CoreData, API, вычисления

class TaskMainInteractor: TaskMainInteractorProtocol {

    weak var presenter: TaskMainPresenterProtocol? // решение проблемы retain cycle при сборке
    
    
    private let container: NSPersistentContainer
    private let jsonService: JsonService
    private var tasks: [DataTask] = [] // Локальный кэш для операций интерактора
    
    // ✅ Dependency Injection для тестов
    init(container: NSPersistentContainer = CoreDataManager.shared.container, jsonService: JsonService = JsonService()) {
        self.container = container
        self.jsonService = jsonService
    }
    // MARK: - Fetch (Read)
    func fetchTasks() {
        let request = NSFetchRequest<DataTask>(entityName: "DataTask")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DataTask.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \DataTask.date, ascending: false)
        ]
        
        do {
            tasks = try container.viewContext.fetch(request)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let presenter = self.presenter else { return }
                print("🪬mainPresenter.didFetchTasks")
                presenter.didFetchTasks(self.tasks)
            }
        } catch {
            print("❌ Ошибка чтения данных: \(error.localizedDescription)")
        }
        
    }
    
    // MARK: - Create
    func createNewTask() -> UUID {
        let newTask = DataTask(context: container.viewContext)
        let id = UUID()
        newTask.id = id
        newTask.title = ""
        newTask.body = ""
        newTask.date = .now
        newTask.isCompleted = false
        
        tasks.append(newTask) // кеш для локальных операций
        
        print("TaskMainInteractor.createNewTask")
        return id
    }
    
    // MARK: - Update
    func toggleTaskCompletion(at id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { print("Не пройден guard") ; return }
        print("TaskMainInteractor.toggleTaskCompletion")
        task.isCompleted.toggle()
        CoreDataManager.shared.saveContext()
        fetchTasks()
    }
    
    // MARK: - Delete
    func deleteTask(at id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        print("TaskMainInteractor.deleteTask")
        container.viewContext.delete(task)
        CoreDataManager.shared.saveContext()
        fetchTasks()
    }
    
    // MARK: - Initial Data
    func loadInitialDataIfNeeded() {
        let hasLoaded = UserDefaults.standard.bool(forKey: "hasLoadedInitialData")
        
        if !hasLoaded && tasks.isEmpty {
            print("hasLoaded and tasks.isEmpty")
            Task {
                do {
                    let apiTasks = try await jsonService.fetchTasks()
                    
                    for apiTask in apiTasks {
                        let newTask = DataTask(context: container.viewContext)
                        newTask.id = UUID()
                        newTask.title = String(apiTask.id)
                        newTask.body = apiTask.todo
                        newTask.date = .now
                        newTask.isCompleted = apiTask.completed
                    }
                    CoreDataManager.shared.saveContext()
                    fetchTasks()
                    UserDefaults.standard.set(true, forKey: "hasLoadedInitialData")
                } catch {
                    print("❌Ошибка загрузки данных из API: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Reset
    func resetAndReload() {
        let request = NSFetchRequest<DataTask>(entityName: "DataTask")
        do {
            let tasks = try container.viewContext.fetch(request)
            for task in tasks {
                container.viewContext.delete(task)
            }
            CoreDataManager.shared.saveContext()
            fetchTasks()
            UserDefaults.standard.removeObject(forKey: "hasLoadedInitialData")
            loadInitialDataIfNeeded()
            print("Сброс произведен")
        } catch {
            print("❌ Ошибка сброса данных: \(error.localizedDescription)")
        }
    }
    
}
