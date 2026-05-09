//
//  Extensions.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

typealias HTTPMethod = String
typealias TimeAmount = TimeInterval

struct HTTPHeaders: Sendable {

    private var headers: [String: String] = [:]

    init(_ headers: [String: String] = [:]) {
        headers.forEach { self.headers[$0.key.lowercased()] = $0.value }
    }

    subscript(name: String) -> String? {
        get { headers[name.lowercased()] }
        set { headers[name.lowercased()] = newValue }
    }

    mutating func add(name: String, value: String) {
        headers[name.lowercased()] = value
    }

    mutating func replaceOrAdd(name: String, value: String) {
        headers[name.lowercased()] = value
    }

    mutating func remove(name: String) {
        headers[name.lowercased()] = nil
    }
}

extension HTTPHeaders: Sequence {

    func makeIterator() -> Dictionary<String, String>.Iterator {
        headers.makeIterator()
    }
}
