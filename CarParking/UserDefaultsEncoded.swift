//
//  UserDefaultsEncoded.swift
//  CarParking
//
//  Created by Mikhail on 02.06.2020.
//  Copyright © 2020 Mikhail. All rights reserved.
//

import Foundation

import UIKit

// Класс, чтобы хранить данные о машине в User defaults

struct UserDefaultsEncoded<T: Codable> {
    
    func encode(key: String, value: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let jsonData = try? encoder.encode(value) else { return }
        let jsonString = String(bytes: jsonData, encoding: .utf8)
        UserDefaults.standard.set(jsonString, forKey: key)
    }
    
    func getValue(for key: String) -> T? {
        guard let jsonString = UserDefaults.standard.string(forKey: key) else {
            return nil
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        guard let value = try? JSONDecoder().decode(T.self, from: jsonData) else {
            return nil
        }
        return value
    }
}
