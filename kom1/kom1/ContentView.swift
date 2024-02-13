import SwiftUI

struct Box: Identifiable, Hashable {
    let id = UUID()
    let number: String
    var status: String
    var firm: String
}

class BoxesViewModel: ObservableObject {
    @Published var boxes = [
        Box(number: "Заказ 1", status: "В пути", firm: "Фирма 1"),
        Box(number: "Заказ 2      ", status: "На складе", firm: "Фирма 1")
    ]
    @Published var selectedBox: Box?
    @Published var searchText = ""
    @Published var searchResult = ""
    @Published var isAddOrderModalPresented = false
    @Published var isImportModalPresented = false
    @Published var isExportModalPresented = false
    @Published var newOrderNumber = ""
    @Published var newOrderFirm = ""
    @Published var newOrderStatus = "В пути"
    @Published var importResolution = ".docx"
    @Published var exportResolution = ".docx"

    func moveToFactory() {
        if let box = selectedBox {
            if let index = boxes.firstIndex(of: box) {
                boxes[index].status = "На складе"
            }
        }
        selectedBox = nil
    }
    
    func moveToDestination() {
        if let box = selectedBox {
            if let index = boxes.firstIndex(of: box) {
                boxes[index].status = "В пути"
            }
        }
        selectedBox = nil
    }
    
    func clearSelection() {
        if let box = selectedBox {
            boxes.removeAll { $0 == box }
            selectedBox = nil
        }
    }
    
    func searchForBox() {
        let matchingBoxes = boxes.filter { $0.number == searchText }
        if let box = matchingBoxes.first {
            searchResult = "Заказ \(box.number) \(box.status)"
        } else {
            searchResult = "Заказ с номером \(searchText) не найден"
        }
        searchText = ""
    }
    
    func addOrder() {
        isAddOrderModalPresented.toggle()
    }
    
    func saveNewOrder() {
        boxes.append(Box(number: newOrderNumber, status: newOrderStatus, firm: newOrderFirm))
        isAddOrderModalPresented.toggle()
        newOrderNumber = ""
        newOrderFirm = ""
        newOrderStatus = "В пути"
    }
    
    func importData() {
        isImportModalPresented.toggle()
    }
    
    func exportData() {
        isExportModalPresented.toggle()
    }
}

struct ContentView: View {
    @StateObject var viewModel = BoxesViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Text("Номер заказа")
                    .font(.custom("Times New Roman", size: 16))
                    .fontWeight(.bold)
                    .italic()
                Spacer()
                Text("Фирма")
                    .font(.custom("Times New Roman", size: 16))
                    .fontWeight(.bold)
                    .italic()
                Spacer()
                Text("Статус отправки")
                    .font(.custom("Times New Roman", size: 16))
                    .fontWeight(.bold)
                    .italic()
            }.padding(.horizontal)
            
            List(viewModel.boxes) { box in
                HStack {
                    Text(box.number)
                    Spacer()
                    Text(box.firm)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                    Text(box.status)
                }
            }
            
            HStack {
                Button("Склад", action: viewModel.moveToFactory)
                Button("Отправить в путь", action: viewModel.moveToDestination)
                Button("Очистить", action: viewModel.clearSelection)
                Button("Добавить заказ", action: viewModel.addOrder)
            }.padding(.horizontal)

            
            HStack {
                VStack {
                    Text("На складе")
                        .font(.custom("Times New Roman", size: 16))
                        .fontWeight(.bold)
                        .italic()
                    TextEditor(text: .constant(boxesText(forStatus: "На складе")))
                        .padding()
                }
                VStack {
                    Text("В пути")
                        .font(.custom("Times New Roman", size: 16))
                        .fontWeight(.bold)
                        .italic()
                    TextEditor(text: .constant(boxesText(forStatus: "В пути")))
                        .padding()
                }
            }
            
            HStack {
                TextField("Поиск по номеру заказа", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Найти", action: viewModel.searchForBox)
            }
            .padding()
            
            Text(viewModel.searchResult)
                .padding()
            
            HStack {
                Button("Импорт", action: viewModel.importData)
                Button("Экспорт", action: viewModel.exportData)
            }.padding(.horizontal)
        }
        .padding()
        .sheet(isPresented: $viewModel.isAddOrderModalPresented) {
            AddOrderView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isImportModalPresented) {
            ImportDataView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isExportModalPresented) {
            ExportDataView(viewModel: viewModel)
        }
    }
    
    func boxesText(forStatus status: String) -> String {
        let boxesWithStatus = viewModel.boxes.filter { $0.status == status }
        let boxesNumbers = boxesWithStatus.map { $0.number }
        return boxesNumbers.joined(separator: "\n")
    }
}

struct AddOrderView: View {
    @ObservedObject var viewModel: BoxesViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Введите номер заказа", text: $viewModel.newOrderNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Picker("Статус", selection: $viewModel.newOrderStatus) {
                    Text("В пути").tag("В пути")
                    Text("На складе").tag("На складе")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                Button("Добавить", action: viewModel.saveNewOrder)
                    .padding()
            }
            .navigationTitle("Добавить заказ")
        }
    }
}

struct ImportDataView: View {
    @ObservedObject var viewModel: BoxesViewModel
    @State private var selectedFileType = FileTypeOptions.docx.rawValue
    
    enum FileTypeOptions: String, CaseIterable, Identifiable {
        case docx = ".docx"
        case doc = ".doc"
        case txt = ".txt"
        case xls = ".xls"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Выберите разрешение файла:")
                Picker(selection: $selectedFileType, label: Text("Тип файла")) {
                    ForEach(FileTypeOptions.allCases) { option in
                        Text(option.rawValue).tag(option.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                TextField("Введите путь к файлу", text: $viewModel.importResolution)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Импортировать", action: {
                    // Perform import operation with viewModel.importResolution
                    viewModel.isImportModalPresented.toggle()
                })
            }
            .navigationTitle("Импорт данных")
        }
    }
}

struct ExportDataView: View {
    @ObservedObject var viewModel: BoxesViewModel
    @State private var selectedFileType = FileTypeOptions.docx.rawValue
    
    enum FileTypeOptions: String, CaseIterable, Identifiable {
        case docx = ".docx"
        case doc = ".doc"
        case txt = ".txt"
        case xls = ".xls"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Выберите разрешение файла:")
                Picker(selection: $selectedFileType, label: Text("Тип файла")) {
                    ForEach(FileTypeOptions.allCases) { option in
                        Text(option.rawValue).tag(option.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                TextField("Введите путь для сохранения файла", text: $viewModel.exportResolution)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Экспортировать", action: {
                    // Perform export operation with viewModel.exportResolution
                    viewModel.isExportModalPresented.toggle()
                })
            }
            .navigationTitle("Экспорт данных")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
