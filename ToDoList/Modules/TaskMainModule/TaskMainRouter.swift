//
//  TaskMainRouter.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import SwiftUI

final class TaskMainRouter: ObservableObject, TaskMainRouterProtocol {

    @Published var path: [UUID] = []

    func showTaskDetail(for id: UUID) {
        path.append(id)
    }
    
    static func build() -> TaskMainView {
        let router = TaskMainRouter()
        let interactor = TaskMainInteractor() // Дефолтная инициализация
        let presenter = TaskMainPresenter(interactor: interactor, router: router)
        
        interactor.presenter = presenter
        presenter.viewDidLoad()
        
        return TaskMainView(vm: presenter, router: router)
    }
    
}
