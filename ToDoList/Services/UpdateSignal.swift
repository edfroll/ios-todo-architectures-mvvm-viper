//
//  UpdateSignal.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//

import Foundation
import Combine

final class UpdateSignal {
    static let shared = UpdateSignal()
    
    private init () {}
    
    let updatePublisher = PassthroughSubject<Void, Never>()
}
