//
//  Prospects.swift
//  HotProspects
//
//  Created by Vladimir on 13.07.2021.
//

import SwiftUI

class Prospect: Identifiable, Codable {
    let id = UUID()
    var name = "Anonymous"
    var emailAddress = ""
    fileprivate(set) var isContacted = false
}

class Prospects: ObservableObject {

    @Published private(set) var people: [Prospect] = []
    
    init() {
        let filename = getDocumentDirectory().appendingPathComponent("SavedPeople")
        
        do {
            let data = try Data(contentsOf: filename)
            let decoded = try JSONDecoder().decode([Prospect].self, from: data)
            self.people = decoded
            
        } catch {
            print(error.localizedDescription)
        }

    }

    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        save()
    }
    
    private func save() {
        
        let filename = getDocumentDirectory().appendingPathComponent("SavedPeople")
        do {
            let data = try JSONEncoder().encode(people)
            try data.write(to: filename, options: [.atomicWrite])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func getDocumentDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }
}


