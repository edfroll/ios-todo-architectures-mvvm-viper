//
//  TaskMainPresenter.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation
import Combine

final class TaskMainPresenter: TaskMainPresenterProtocol, ObservableObject {
    
    private let interactor: TaskMainInteractorProtocol
    private let router: TaskMainRouterProtocol
    
    @Published var displayTasks: [TaskDisplayModel] = []
    @Published var searchText: String = ""
    @Published var isReloading: Bool = false
    
    init(interactor: TaskMainInteractorProtocol, router: TaskMainRouterProtocol) {
        self.interactor = interactor
        self.router = router
        setupUpdateObserver()
        setupResetAndReloadObserver()
    }

    private var cancellables = Set<AnyCancellable>()
    private var rawTasks: [DataTask] = []
    
    func setupUpdateObserver() {
        UpdateSignal.shared.updatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.interactor.fetchTasks()
            }
            .store(in: &cancellables)
    }
    
    func setupResetAndReloadObserver() {
        interactor.reloadCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isReloading = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - View Events
    func viewDidLoad() {
        interactor.fetchTasks()
        interactor.loadInitialDataIfNeeded()
    }
    
    func userDidSearch() {
        filterAndShowTasks()
    }
    
    func userDidTapAddTask() {
        let id = interactor.createNewTask()
        router.showTaskDetail(for: id)
    }
    
    func userDidTapReset() {
        guard !isReloading else { return }
        
        isReloading = true
        interactor.resetAndReload()
    }
    
    func userDidTapToggleCompletion(for id: UUID) {
        interactor.toggleTaskCompletion(at: id)
    }
    
    func userDidTapDelete(for id: UUID) {
        interactor.deleteTask(at: id)
    }
    
    func userDidTapEdit(for id: UUID) {
        router.showTaskDetail(for: id)
    }
    
    func didFetchTasks(_ tasks: [DataTask]) {
        rawTasks = tasks
        filterAndShowTasks()
    }
        
    // MARK: - Helpers
    /// Единственное место обновления TaskMainView
    private func filterAndShowTasks() {
        let filtered = searchText.isEmpty ? rawTasks : rawTasks.filter { task in
            (task.title ?? "").localizedCaseInsensitiveContains(searchText) ||
            (task.body ?? "").localizedCaseInsensitiveContains(searchText)
        }
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            let filteredForDisplayTasks = filtered.map { task in
                TaskDisplayModel(
                    id: task.id ?? UUID(),
                    title: task.title ?? "",
                    body: task.body ?? "",
                    dateString: DateFormatter.ddMMyyyy.string(from: task.date ?? Date()),
                    isCompleted: task.isCompleted
                )
            }
            DispatchQueue.main.async {
                self.displayTasks = filteredForDisplayTasks
            }
        }
    }
    
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

