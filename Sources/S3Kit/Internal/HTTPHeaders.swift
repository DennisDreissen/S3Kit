//
//  HTTPHeaders.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

struct HTTPHeaders: Sendable {

    private var headers: [String: String] = [:]

    init(_ headers: [String: String] = [:]) {
        headers.forEach { self.headers[$0.key.lowercased()] = $0.value }
    }

    subscript(name: String) -> String? {
        get { headers[name.lowercased()] }
        set { headers[name.lowercased()] = newValue }
    }

    mutating func setIfMissing(_ value: String?, for key: String) {
        guard let value else {
            return
        }

        let key = key.lowercased()

        if headers[key] == nil {
            headers[key] = value
        }
    }
}

extension HTTPHeaders: Sequence {

    func makeIterator() -> Dictionary<String, String>.Iterator {
        headers.makeIterator()
    }
}
