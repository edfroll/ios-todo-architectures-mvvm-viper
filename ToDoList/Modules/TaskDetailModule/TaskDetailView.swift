//
//  TaskDetailView.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import SwiftUI

struct TaskDetailView: View {
    
    @StateObject var vm: TaskDetailPresenter
    @StateObject var router: TaskDetailRouter
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            // MARK: - Main UI
            VStack(alignment: .leading, spacing: 20) {
                // Заголовок
                TextField("Заголовок задачи", text: $vm.title, axis: .vertical)
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                    .padding(.top, 12)
                // Дата
                Text(vm.dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                // Основной текст
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $vm.body)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.primary)
                        .frame(minHeight: 100)
                    if vm.body.isEmpty {
                        Text("Введите описание задачи...")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.gray.opacity(0.5))
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            // MARK: Toolbar
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        vm.userDidTapBack()
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
        }
        
        
        .scrollDismissesKeyboard(.immediately)
    }
    
}
