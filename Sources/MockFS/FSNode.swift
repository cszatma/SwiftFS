//
//  FSNode.swift
//  MockFS
//
//  Created by Christopher Szatmary on 2019-09-01.
//

import Foundation

class FSNode {
    var name: String
    weak var parent: FSNode!
    let isDir: Bool
    var data: Data?
    var contents: [String: FSNode]

    private init(name: String, parent: FSNode?, isDir: Bool, data: Data?, contents: [String: FSNode]) {
        self.name = name
        self.parent = parent
        self.isDir = isDir
        self.data = data
        self.contents = contents
    }

    func copy(name: String? = nil, parent: FSNode? = nil) -> FSNode {
        guard isDir else {
            return FSNode.file(name: name ?? self.name, parent: parent ?? self.parent, data: data)
        }

        let copiedNode = FSNode.dir(name: name ?? self.name, parent: parent ?? self.parent, contents: [:])
        for (name, node) in contents {
            copiedNode.contents[name] = node.copy(parent: copiedNode)
        }

        return copiedNode
    }

    static func file(name: String, parent: FSNode, data: Data?) -> FSNode {
        return FSNode(name: name, parent: parent, isDir: false, data: data, contents: [:])
    }

    static func dir(name: String, parent: FSNode?, contents: [String: FSNode]) -> FSNode {
        return FSNode(name: name, parent: parent, isDir: true, data: nil, contents: contents)
    }
}
