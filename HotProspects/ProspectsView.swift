//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Vladimir on 13.07.2021.
//

import SwiftUI
import CodeScanner
import UserNotifications

struct ProspectsView: View {
    @State private var isShowingScanner = false
    @State private var showingFilterSheet = false
    @EnvironmentObject var prospects: Prospects
    
    enum FilterType {
        case none, contacted, uncontacted
    }
    
    let filter: FilterType
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }
    
    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter { $0.isContacted }
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }
    
    @State private var sortType: SortType = .none
    
    enum SortType {
        case byName, byDate, none
    }
    
    private var sortedProspects: [Prospect] {
        switch sortType {
        case .byName:
            return filteredProspects.sorted {
                $0.name < $1.name
            }
        case .byDate:
            return filteredProspects.sorted {
                $0.createDate < $1.createDate
            }
            
        case .none:
            return filteredProspects
            
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedProspects) { prospect in
                    VStack(alignment: .leading) {
                        Text(prospect.name)
                            .font(.headline)
                        Text(prospect.emailAddress)
                            .foregroundColor(.secondary)
                        if filter == .none {
                            Image(systemName: prospect.isContacted ? "checkmark.circle" : "questionmark.diamond")
                        }
                        
                    }
                    .contextMenu {
                        Button(prospect.isContacted ? "Mark Uncontacted" : "Mark Contacted") {
                            self.prospects.toggle(prospect)
                        }
                        if !prospect.isContacted {
                            Button("Remind Me") {
                                self.addNotification(for: prospect)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.isShowingScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scan")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        self.showingFilterSheet = true
                    } label: {
                        Text("Filter")
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr], simulatedData: " Luka Bernardi\nluka.bernardi@gmail.com", completion: self.handleScan)
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("How to sort?"), buttons: [
                    .default(Text("By name")) { sortType = .byName },
                    .default(Text("By date")) { sortType = .byDate },
                    .cancel()
                ])
            }
        
                
        }
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        self.isShowingScanner = false
        switch result {
        case .success(let code):
            let details = code.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            
            self.prospects.add(person)
            
        case .failure(let error):
            print("Scanning failed")
        }
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
            var dateComponents = DateComponents()
            dateComponents.hour = 9
         //   let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    
                    if success {
                        addRequest()
                    } else {
                        print("D' oh")
                    }
                }
            }
        }
    }
}

