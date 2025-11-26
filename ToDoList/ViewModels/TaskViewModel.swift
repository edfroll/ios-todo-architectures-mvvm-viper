//
//  TaskViewModel.swift
//  ToDoList
//
//  Created by Эдвард on 18.09.2025.
//
import SwiftUI
import CoreData

@MainActor
class TaskViewModel: ObservableObject {
    
    let container: NSPersistentContainer
    var jsonVM: JsonViewModel = JsonViewModel()
    
    @Published var tasks: [DataTask] = []
    @Published var searchText: String = ""
    
    
    init() {
        container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Ошибка загрузки CoreData: \(error.localizedDescription)")
            }
        }
        fetchData()
        loadInitialDataIfNeeded()
    }
    
    func loadInitialDataIfNeeded() {
        let hasLoaded = UserDefaults.standard.bool(forKey: "hasLoadedInitialData")
        
        if !hasLoaded && tasks.isEmpty {
            loadTasksFromApi()
            UserDefaults.standard.set(true, forKey: "hasLoadedInitialData")
        }
    }
    
    // MARK: - Network
    func loadTasksFromApi() {
        print("Вызван метод loadTasksFromApi")
        Task {
            do {
                let apiTasks = try await jsonVM.fetchTasks()
                
                for apiTask in apiTasks {
                    let newTask = DataTask(context: container.viewContext)
                    newTask.id = UUID()
                    newTask.title = String(apiTask.id)
                    newTask.body = String(apiTask.todo)
                    newTask.date = .now
                    newTask.isCompleted = apiTask.completed
                }
                saveContext()
                fetchData()// здесь нужен main!
            } catch {
                print("Ошибка загрузки данных из API: \(error)")
            }
        }
    }

    // MARK: - Create
    func createNewTask() -> UUID {
        let newTask = DataTask(context: container.viewContext)
        newTask.id = UUID()
        newTask.title = ""
        newTask.body = ""
        newTask.date = Date.now
        newTask.isCompleted = false
        
        saveContext()
        fetchData()
        
        return newTask.id!
    }
    
    // MARK: - Read
    func fetchData() {
        let request = NSFetchRequest<DataTask>(entityName: "DataTask")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DataTask.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \DataTask.date, ascending: false)
        ]
        do {
            tasks = try container.viewContext.fetch(request) // viewContext.fetch по умолчанию выполняется в каком потоке? Фоновом? А то у меня фиолетовая ошибка в рантайме вылетала на эту строку мол Main Thread Violation
        } catch {
            print("Ошибка загрузки данных: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update
    func updateTask(id: UUID, newTitle: String, newBody: String) {
        guard !newTitle.isEmpty || !newBody.isEmpty else { return removeTask(at: id) }
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        
        var didChange = false
        defer {
            if didChange {
                task.date = Date.now
                saveContext()
                fetchData()
            }
        }
        
        if task.title != newTitle {
            task.title = newTitle
            didChange = true
        }
        if task.body != newBody {
            task.body = newBody
            didChange = true
        }
    }
    
    func toggleTaskCompletion(at id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        
        task.isCompleted.toggle()
        
        saveContext()
        fetchData()
    }

    // MARK: - Delete
    func removeTask(at id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        
        container.viewContext.delete(task)
        
        saveContext()
        fetchData()
    }
    /*
     1. Оттебажить кнопку reset and reload.
     2. ViewModel - @MainActor. Все остальное - сервисы (если есть резон(тяжелые задачи)
     3. Я написал loadTaskFromApi, осталось все проверить и шлейфануть SwiftUI + MVVM + Core Data + async/await
     */
    
    // MARK: - Helper
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Ошибка сохранения \(error.localizedDescription)")
            }
        }
        print("viewContext сохранен")
    }

    // MARK: - Reset and Reload
    func resetAndReload() {
        for task in tasks {
            container.viewContext.delete(task)
        }
        saveContext()
        UserDefaults.standard.removeObject(forKey: "hasLoadedInitialData")
        
        loadTasksFromApi()
    }
    
    // MARK: - Formatting
    var filteredTasks: [DataTask] {
        if searchText.isEmpty {
            return tasks
        } else {
            return tasks.filter { task in
                (task.title ?? "").localizedCaseInsensitiveContains(searchText) ||
                (task.body ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yy"
        return df
    }()
    
    func taskCountText(for count: Int) -> String {
        let remainder10 = count % 10
        let remainder100 = count % 100
        
        if remainder100 >= 11 && remainder100 <= 14 {
            return "\(count) задач"
        }
        switch remainder10 {
        case 1:
            return "\(count) задача"
        case 2...4:
            return "\(count) задачи"
        default:
            return "\(count) задач"
        }
    }
}


