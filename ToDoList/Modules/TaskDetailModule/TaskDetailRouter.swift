//
//  TaskDetailRouter.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation

final class TaskDetailRouter: TaskDetailRouterProtocol, ObservableObject {
    
    static func createModule(taskId: UUID) -> TaskDetailView {
        let router = TaskDetailRouter()
        let interactor = TaskDetailInteractor(taskId: taskId, container: CoreDataManager.shared.container)
        let presenter = TaskDetailPresenter(interactor: interactor, router: router)
        
        interactor.presenter = presenter
        presenter.viewDidLoad()
        
        return TaskDetailView(vm: presenter, router: router)
    }
    
}
