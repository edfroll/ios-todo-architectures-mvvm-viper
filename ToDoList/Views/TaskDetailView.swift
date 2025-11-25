//
//  TaskDetailView.swift
//  ToDoList
//
//  Created by Эдвард on 25.11.2025.
//
import SwiftUI
// unknown
struct TaskDetailView: View {
    
    let taskId: UUID
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newTitle = ""
    @State private var newBody = ""
    
   // @FocusState private var isDescriptionFocused: Bool
    
    private var task: TaskModel? {
        viewModel.tasks.first(where: { $0.id == taskId })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Заголовок
                TextField("Заголовок задачи", text: $newTitle, axis: .vertical)
                //.font(.system(.title, weight: .semibold))
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                // Дата
                if let task = task, let date = task.date {
                    Text(viewModel.formatter.string(from: date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                // Основной текст
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $newBody)
                            .font(.system(size: 18))
                            .foregroundStyle(Color.primary)
                            .frame(minHeight: 100)
                            //.focused($isDescriptionFocused)
                    if newBody.isEmpty {
                            Text("Введите описание задачи...")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.gray.opacity(0.5))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8) // почему он необходим?
                                .allowsHitTesting(false)
                        }
                }
                .padding(.horizontal)
                Spacer()
                
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                .fontWeight(.semibold)
                            Text("Назад")
                                .font(.system(size: 18))
                        }
                       
                        
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .onAppear {
                if let task = task {
                    newTitle = task.title ?? ""
                    newBody = task.body ?? ""
                    //isDescriptionFocused = true
                }
            }
            
            .onDisappear {
                viewModel.updateTask(id: taskId, newTitle: newTitle, newBody: newBody)

            }
        }
        .scrollDismissesKeyboard(.immediately)
    }
    
    
}
/*
 Single Source of Truth (единственный источник истины) - данные должны храниться в одном месте (viewModel.tasks), а все остальные части приложения должны ссылаться на эти данные, а не создавать их копии.
 */
//                viewModel.updateTask(id: taskId, newTitle: newTaskTitle, newDescription: newTaskDescription)
#Preview {
//    TaskDetailView(task: TaskModel(title: "TaskTitle", description: "Test description", date: .now, isCompleted: false), viewModel: TaskViewModel())
}
