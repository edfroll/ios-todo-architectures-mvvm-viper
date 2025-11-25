//
//  TaskDetailPresenterTests.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import XCTest
import CoreData

@testable import ToDoList

final class TaskDetailPresenterTests: XCTestCase {
    
    var sut: TaskDetailPresenter!
    var mockInteractor: MockTaskDetailInteractor!
    var mockRouter: MockTaskDetailRouter!
    
    override func setUp() {
        super.setUp()
        mockInteractor = MockTaskDetailInteractor()
        mockRouter = MockTaskDetailRouter()
        sut = TaskDetailPresenter(interactor: mockInteractor, router: mockRouter)
    }
    
    override func tearDown() {
        sut = nil
        mockInteractor = nil
        mockRouter = nil
        super.tearDown()
    }
    
    // MARK: Helper
    private func createMockDataTask(title: String, body: String) -> DataTask {
        let context = MockCoreDataStack.shared.context
        let task = DataTask(context: context)
        task.id = UUID()
        task.title = title
        task.body = body
        task.date = Date()
        task.isCompleted = false
        return task
    }
    
    // MARK: - Tests: View Did Load
    func testViewDidLoad_CallsFetchTask() {
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertTrue(mockInteractor.fetchTaskCalled)
    }
    
    // MARK: - Tests: Did Fetch Task
    func testDidFetchTask_UpdatesPublishedProperties() {
        // Given
        let task = createMockDataTask(title: "Test Title", body: "Test Body")
        
        // When
        sut.didFetchTask(task)
        
        // Then
        let expectation = XCTestExpectation(description: "Properties updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.sut.title, "Test Title")
            XCTAssertEqual(self.sut.body, "Test Body")
            XCTAssertFalse(self.sut.dateString.isEmpty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDidFetchTask_FormatsDateCorrectly() {
        // Given
        let calendar = Calendar.current
        let components = DateComponents(year: 2025, month: 11, day: 21)
        let date = calendar.date(from: components)
        
        let context = MockCoreDataStack.shared.context
        let task = DataTask(context: context)
        task.id = UUID()
        task.title = "Test"
        task.body = "Body"
        task.date = date
        task.isCompleted = false
        
        // When
        sut.didFetchTask(task)
        
        // Then
        let expectation = XCTestExpectation(description: "Date formatted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.sut.dateString, "21/11/2025")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Tests: User Did Tap Back - Empty Fields
    func testUserDidTapBack_BothFieldsEmpty_DeletesTask() {
        // Given
        let task = createMockDataTask(title: "Title", body: "Body")
        sut.didFetchTask(task)
        
        let fetchExpectation = XCTestExpectation(description: "Fetch completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        sut.title = ""
        sut.body = ""
        
        // When
        sut.userDidTapBack()
        
        // Then
        XCTAssertTrue(mockInteractor.deleteTaskCalled)
        XCTAssertFalse(mockInteractor.updateTaskCalled)
    }
    
    func testUserDidTapBack_TitleEmptyButBodyNot_DoesNotDelete() {
        // Given
        let task = createMockDataTask(title: "Title", body: "Body")
        sut.didFetchTask(task)
        
        let fetchExpectation = XCTestExpectation(description: "Fetch complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        sut.title = ""
        sut.body = "Some body"
        
        // When
        sut.userDidTapBack()
        
        // Then
        XCTAssertFalse(mockInteractor.deleteTaskCalled)
    }
    
    // MARK: - Tests: User Did Tap Back - No Changes
    func testUserDidTapBack_NoChanges_DoesNothing() {
        // Given
        let task = createMockDataTask(title: "Title", body: "Body")
        sut.didFetchTask(task)
        
        let fetchExpectation = XCTestExpectation(description: "Fetch complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // Не меняем title и body
        
        // When
        sut.userDidTapBack()
        
        // Then
        XCTAssertFalse(mockInteractor.updateTaskCalled)
        XCTAssertFalse(mockInteractor.deleteTaskCalled)
    }
    
    // MARK: - Test: User Did Tap Back - Update Both
    func testUserDidTapBack_BothFieldsChanged_UpdatesBoth() {
        // Given
        let task = createMockDataTask(title: "Title", body: "Body")
        sut.didFetchTask(task)
        
        let fetchExpectation = XCTestExpectation(description: "Fetch complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        sut.title = "New title"
        sut.body = "New body"
        
        // When
        sut.userDidTapBack()
        
        // Then
        XCTAssertTrue(mockInteractor.updateTaskCalled)
        XCTAssertEqual(mockInteractor.updateTaskTitle, "New title")
        XCTAssertEqual(mockInteractor.updateTaskBody, "New body")
    }
    
    // MARK: - Tests: User Did Tap Back - Update Title Only
    func testUserDidTapBack_OnlyTitleChanged_UpdatesTitle() {
        // Given
        let task = createMockDataTask(title: "Title", body: "Body")
        sut.didFetchTask(task)
        
        let fetchExpectation = XCTestExpectation(description: "Fetch complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        sut.title = "New Title"
        // body остается без изменений
        
        // When
        sut.userDidTapBack()
        
        // Then
        XCTAssertTrue(mockInteractor.updateTaskCalled)
        XCTAssertEqual(mockInteractor.updateTaskTitle, "New Title")
        XCTAssertNil(mockInteractor.updateTaskBody)
    }
    
    // MARK: - Tests: User Did Tap Back - Update Body Only
    func testUserDidTapBack_OnlyBodyChanged_UpdatesBody() {
        // Given
        let task = createMockDataTask(title: "Title", body: "Body")
        sut.didFetchTask(task)
        
        let fetchExpectation = XCTestExpectation(description: "Fetch Complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        sut.body = "New Body"
        // title остается без изменений
        
        // When
        sut.userDidTapBack()
        
        // Then
        XCTAssertTrue(mockInteractor.updateTaskCalled)
        XCTAssertNil(mockInteractor.updateTaskTitle)
        XCTAssertEqual(mockInteractor.updateTaskBody, "New Body")
    }
}

// MARK: - Mock Interactor
    
class MockTaskDetailInteractor: TaskDetailInteractorProtocol {
    var presenter: TaskDetailPresenterProtocol?
    
    var fetchTaskCalled = false
    var updateTaskCalled = false
    var deleteTaskCalled = false
    
    var updateTaskTitle: String?
    var updateTaskBody: String?
    
    func fetchTask() {
        fetchTaskCalled = true
    }
    
    func updateTask(_ newTitle: String?, _ newBody: String?) {
        updateTaskCalled = true
        updateTaskTitle = newTitle
        updateTaskBody = newBody
    }
    
    func deleteTask() {
        deleteTaskCalled = true
    }
}

// MARK: - Mock Router

class MockTaskDetailRouter: TaskDetailRouterProtocol {
    
    static func createModule(taskId: UUID) -> TaskDetailView {
        fatalError("Not implemented in tests")
    }
}

