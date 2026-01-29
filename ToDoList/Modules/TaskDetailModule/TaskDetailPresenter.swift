//
//  TaskDetailPresenter.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation

final class TaskDetailPresenter: TaskDetailPresenterProtocol, ObservableObject {
    
    // MARK: Properties
    private let interactor: TaskDetailInteractorProtocol
    private let router: TaskDetailRouterProtocol
    
    private var displayTask: TaskDisplayModel?
    
    init(interactor: TaskDetailInteractorProtocol, router: TaskDetailRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }
    
    @Published  var title: String = ""
    @Published  var body: String = ""
    @Published  var dateString: String = ""
    
    // MARK: Presenter Logic
    func viewDidLoad() {
        interactor.fetchTask()
    }
    
    func didFetchTask(_ dataTask: DataTask) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            displayTask = TaskDisplayModel(
                id: dataTask.id ?? UUID(),
                title: dataTask.title ?? "",
                body: dataTask.body ?? "",
                dateString: DateFormatter.ddMMyyyy.string(from: dataTask.date ?? Date()),
                isCompleted: dataTask.isCompleted
            )
            DispatchQueue.main.async {
                self.showTask()
            }
        }
    }
    /// метод для масштабируемости, как и сам displayTask
    func showTask() {
        guard let displayTask = displayTask else { return } // хотя можно и force unwrap
        title = displayTask.title
        body = displayTask.body
        dateString = displayTask.dateString
    }
    
    func userDidTapBack() {
        if title.isEmpty && body.isEmpty {
            interactor.deleteTask()
            return
        }

        let titleChanged = title != displayTask?.title
        let bodyChanged = body != displayTask?.body
        
        switch (titleChanged, bodyChanged) {
        case (false, false): break
            
        case (true, true): interactor.updateTask(title, body)
        case (true, false): interactor.updateTask(title, nil)
        case (false, true): interactor.updateTask(nil, body)
        }
    }

    func didChangeTask() {
        CoreDataManager.shared.saveContext() // Общий метод сохранения
        UpdateSignal.shared.updatePublisher.send() // Сигнал обновления для MainModule
        
    }
    
}
