//
//  TaskMainInteractor.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation
import CoreData
import Combine

final class TaskMainInteractor: TaskMainInteractorProtocol {
    
    weak var presenter: TaskMainPresenterProtocol?
    
    private let container: NSPersistentContainer
    private let jsonService: JsonService
    private var tasks: [DataTask] = [] // Локальный кэш для операций интерактора
    
    let reloadCompleted = PassthroughSubject<Void, Never>()
    private var isReloading = false
    
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
            tasks = try container.viewContext.fetch(request) // простой fetch - background thread не нужен
            presenter?.didFetchTasks(self.tasks) // главный поток ✅
            
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
        
        return id
    }
    
    // MARK: - Update
    func toggleTaskCompletion(at id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        task.isCompleted.toggle()
        CoreDataManager.shared.saveContext()
        fetchTasks()
    }
    
    // MARK: - Delete
    func deleteTask(at id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        container.viewContext.delete(task)
        CoreDataManager.shared.saveContext()
        fetchTasks()
    }
    
    // MARK: - Initial Data
    func loadInitialDataIfNeeded() {
        let hasLoaded = UserDefaults.standard.bool(forKey: "hasLoadedInitialData")
        
        guard !hasLoaded && tasks.isEmpty else { return }
        
        print("🔄 Загрузка начальных данных из API...")
        
        fetchTasksFromApi { [weak self] success in
            guard self != nil else { return }
            
            if success {
                UserDefaults.standard.set(true, forKey: "hasLoadedInitialData")
                print("✅ Начальные данные загружены успешно")
            } else {
                print("❌ Не удалось загрузить начальные данные")
            }
        }
    }
    
    // MARK: - API Integration
        /// Загружает задачи из API и сохраняет в CoreData
        // Parameter completion: Callback с результатом операции (true = успех, false = ошибка)
        private func fetchTasksFromApi(completion: @escaping (Bool) -> Void) {
            
            jsonService.fetchTasks { [weak self] result in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                switch result {
                case .success(let apiTasks):
                    print("✅ Получено \(apiTasks.count) задач из API")
                    
                    // сохраняем в фоновом потоке для не блокировки UI
                    self.container.performBackgroundTask { context in
                        
                        // создаем задачи в background context
                        for apiTask in apiTasks {
                            let newTask = DataTask(context: context)
                            newTask.id = UUID()
                            newTask.title = String(apiTask.id)
                            newTask.body = apiTask.todo
                            newTask.date = .now
                            newTask.isCompleted = apiTask.completed
                        }
                        
                        // сохраняем изменения
                        do {
                            try context.save()
                            
                            // обновляем UI на главном потоке
                            DispatchQueue.main.async {
                                self.fetchTasks()
                                completion(true)
                            }
                            
                        } catch {
                            print("❌ Ошибка сохранения CoreData: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                completion(false)
                            }
                        }
                    }
                    
                case .failure(let error):
                    // Уже на main thread благодаря JsonService
                    print("❌ Ошибка загрузки из API: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
        
        // MARK: - Reset & Reload
        
        func resetAndReload() {
            guard !isReloading else {
                print("⚠️ Перезагрузка уже выполняется")
                return
            }
            
            isReloading = true
            print("🔄 Сброс и перезагрузка данных...")
            
            // удаляем все задачи
            deleteAllTasks { [weak self] success in
                guard let self = self, success else {
                    self?.finishReloading(success: false)
                    return
                }
                
                // сбрасываем флаг
                UserDefaults.standard.removeObject(forKey: "hasLoadedInitialData")
                
                // загружаем новые данные
                self.fetchTasksFromApi { [weak self] success in
                    guard let self = self else { return }
                    
                    // завершаем с задержкой для плавной анимации
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.finishReloading(success: success)
                    }
                }
            }
        }
        
        /// Удаляет все задачи из базы
        private func deleteAllTasks(completion: @escaping (Bool) -> Void) {
            let request = NSFetchRequest<DataTask>(entityName: "DataTask")
            
            do {
                let tasks = try container.viewContext.fetch(request)
                
                for task in tasks {
                    container.viewContext.delete(task)
                }
                
                try container.viewContext.save()
                self.tasks.removeAll()
                
                DispatchQueue.main.async {
                    self.fetchTasks()
                    completion(true)
                }
                
            } catch {
                print("❌ Ошибка удаления задач: \(error.localizedDescription)")
                completion(false)
            }
        }
        
        /// Завершает процесс перезагрузки
        private func finishReloading(success: Bool) {
            isReloading = false
            reloadCompleted.send()
            
            if success {
                print("✅ Данные успешно перезагружены")
            } else {
                print("⚠️ Перезагрузка завершена с ошибками")
            }
        }
    }
