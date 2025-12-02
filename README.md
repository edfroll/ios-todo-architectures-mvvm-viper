# iOS To-Do App: MVVM vs VIPER

A practical comparison of two popular iOS architectural patterns implemented in a single To-Do application.

## Overview

This project demonstrates the same To-Do app functionality using two different architectures:
- **MVVM** (Model-View-ViewModel)
- **VIPER** (View-Interactor-Presenter-Entity-Router)

Both implementations share the same UI/UX, CoreData models, and API services — only the architectural layer differs.

## Features

- Create, edit, and delete tasks
- Mark tasks as completed
- Search functionality
- Swipe actions and context menus
- Initial data loading from API
- Local persistence with CoreData
- Animated refresh button

## Tech Stack

- **Language:** Swift 5.9
- **UI Framework:** SwiftUI
- **Data Persistence:** CoreData
- **Networking:** URLSession with async/await
- **Reactive Programming:** Combine (VIPER implementation)
- **Minimum iOS:** 17.0+

## Project Structure
```
ToDoApp/
├── MVVM/                   # MVVM implementation
│   ├── ViewModels/
│   ├── Views/
│   └── Models/
│
├── VIPER/                  # VIPER implementation
│   ├── Presenter/
│   ├── Interactor/
│   ├── Router/
│   ├── Protocols/
│   └── View/
│
└── Shared/                 # Shared resources
    ├── CoreData/
    └── Services/
```

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/edfroll/ios-todo-architectures-mvvm-viper.git
```

2. Open in Xcode:
```bash
cd ios-todo-architectures-mvvm-viper
open ToDoApp.xcodeproj
```

3. Select a scheme (MVVM or VIPER) and run

## Architecture Comparison

### MVVM
**Pros:**
- Simpler and faster to implement
- Less boilerplate code
- Native integration with SwiftUI
- Easy to test ViewModels

**Cons:**
- ViewModels can grow large
- Navigation logic mixed with business logic

### VIPER
**Pros:**
- Clear separation of concerns
- Highly testable and maintainable
- Better for large teams
- Easy to replace individual layers

**Cons:**
- More boilerplate code
- Steeper learning curve
- Overkill for small projects

## API

The project uses [DummyJSON API](https://dummyjson.com/todos) for initial data:
```
GET https://dummyjson.com/todos
```

## Requirements

- Xcode 15.0+
- iOS 17.0+
- macOS 14.0+ (for development)
