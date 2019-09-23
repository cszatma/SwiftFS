//
//  MockFileManager.swift
//  MockFS
//
//  Created by Christopher Szatmary on 2019-09-01.
//

import Foundation
import SwiftFS

public class MockFileManager {
    enum Error: Swift.Error {
        case nodeNotFound(name: String)
        case nodeExists
        case invalidName
        case invalidPath
        case notADir
    }

    private var root: FSNode
    private var cwd: FSNode

    public init() {
        root = FSNode.root()
        cwd = root
    }

    // MARK: - JSON Representation

    public convenience init(json: [String: Any]) {
        self.init()
        root.append(json: json)
    }

    public convenience init(jsonData: Data) {
        let json = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
        self.init(json: json)
    }

    public func cd(toPath path: String) throws {
        cwd = try resolveNode(atPath: path)
    }

    public func pwd() -> String {
        return resolveAbsolutePath(fromNode: cwd)
    }

    public func addDirectory(atPath path: String, withName name: String) throws {
        guard isNameValid(name) else {
            throw Error.invalidName
        }

        let node = try resolveNode(atPath: path)
        let dirNode = FSNode.dir(name: name, parent: node, contents: [:])
        try addNode(dirNode, toNode: node)
    }

    public func addFile(atPath path: String, withName name: String, data: Data? = nil) throws {
        guard isNameValid(name) else {
            throw Error.invalidName
        }

        let node = try resolveNode(atPath: path)
        let fileNode = FSNode.file(name: name, parent: node, data: data)
        try addNode(fileNode, toNode: node)
    }

    // MARK: - Private methods

    private func resolveAbsolutePath(fromNode node: FSNode) -> String {
        var path = node.name
        var currentNode: FSNode = node.parent

        while currentNode !== root {
            path = "\(currentNode.name)/\(path)"
            currentNode = currentNode.parent
        }

        return "/\(path)"
    }

    private func resolveNode(atPath path: String) throws -> FSNode {
        let isAbsolute = path.first == "/"
        let baseNode = isAbsolute ? root : cwd
        let components = path.components(separatedBy: "/").filter { $0 != "" }

        var currentNode = baseNode
        for item in components {
            if item == ".." {
                currentNode = currentNode.parent
                continue
            }

            guard let childNode = currentNode.contents[item] else {
                throw Error.nodeNotFound(name: "\(resolveAbsolutePath(fromNode: currentNode))/\(item)")
            }

            currentNode = childNode
        }

        return currentNode
    }

    private func addNode(_ node: FSNode, toNode parentNode: FSNode) throws {
        guard parentNode.isDir else {
            throw Error.notADir
        }

        if parentNode.contents[node.name] != nil {
            throw Error.nodeExists
        }

        parentNode.contents[node.name] = node
    }

    private func isNameValid(_ name: String) -> Bool {
        if name.contains("/") {
            return false
        }

        return true
    }

    private func getDirAndName(fromPath path: String) -> (dirPath: String, name: String)? {
        let components = path.components(separatedBy: "/")
        let count = components.count

        guard count > 2 else {
            return nil
        }

        let name = components[count - 1]
        let dirPath = components.dropLast().joined(separator: "/")
        return (dirPath, name)
    }
}

// MARK: - FSManager

extension MockFileManager: FSManager {
    public func fileExists(atPath path: String) -> Bool {
        return fileExists(atPath: path, isDirectory: nil)
    }

    public func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        guard let node = try? resolveNode(atPath: path) else {
            return false
        }

        if isDirectory != nil {
            isDirectory?.pointee = ObjCBool(node.isDir)
        }

        return true
    }

    public func copyItem(atPath srcPath: String, toPath dstPath: String) throws {
        let node = try resolveNode(atPath: srcPath)
        guard let (destDir, destName) = getDirAndName(fromPath: dstPath) else {
            throw Error.invalidPath
        }

        let destDirNode = try resolveNode(atPath: destDir)
        let copiedNode = node.copy(name: destName, parent: destDirNode)
        try addNode(copiedNode, toNode: destDirNode)
    }

    public func moveItem(atPath srcPath: String, toPath dstPath: String) throws {
        try copyItem(atPath: srcPath, toPath: dstPath)
        try removeItem(atPath: srcPath)
    }

    public func removeItem(atPath path: String) throws {
        let node = try resolveNode(atPath: path)
        node.parent.contents[node.name] = nil
    }

    public func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes _: [FileAttributeKey: Any]?) throws {
        if !createIntermediates {
            guard let (parentPath, name) = getDirAndName(fromPath: path) else {
                throw Error.invalidPath
            }

            try addDirectory(atPath: parentPath, withName: name)
            return
        }

        let components = path.components(separatedBy: "/").filter { $0 != "" }
        var currentNode = path.starts(with: "/") ? root : cwd

        for component in components {
            if let existingNode = currentNode.contents[component] {
                currentNode = existingNode
                continue
            }

            let dirNode = FSNode.dir(name: component, parent: currentNode, contents: [:])
            currentNode.contents[component] = dirNode
            currentNode = dirNode
        }
    }

    public func createFile(atPath path: String, contents data: Data?, attributes _: [FileAttributeKey: Any]?) -> Bool {
        guard let (dirPath, name) = getDirAndName(fromPath: path) else {
            return false
        }

        return (try? addFile(atPath: dirPath, withName: name, data: data)) != nil
    }

    public func contentsOfDirectory(atPath path: String) throws -> [String] {
        let node = try resolveNode(atPath: path)

        guard node.isDir else {
            throw Error.notADir
        }

        var names: [String] = []
        for (name, _) in node.contents {
            names.append(name)
        }

        return names
    }

    public func contents(atPath path: String) -> Data? {
        guard let node = try? resolveNode(atPath: path), !node.isDir else {
            return nil
        }

        return node.data
    }
}
