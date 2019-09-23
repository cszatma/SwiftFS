//
//  SwiftFS.swift
//  SwiftFS
//
//  Created by Christopher Szatmary on 2019-06-16.
//

import Foundation

let fs = FS(manager: FileManager.default)

public final class FS {
    public enum Error: Swift.Error {
        case readFailed
        case writeFailed
        case fileCreationFailed
    }

    private let manager: FSManager

    /**
     Cretes a new FS instance.
     - parameter manager: The `FileManager` to use.
     */
    public init(manager: FSManager) {
        self.manager = manager
    }

    /**
     Expands a tilde at the start of a given path.
     - parameter path: The path to expand.
     - returns: A new path with the tilde expanded.
     */
    private func expand(path: String) -> String {
        return path.first == "~" ? (path as NSString).expandingTildeInPath : path
    }

    /**
     Returns the base name of the given path. For example, `"/tmp/scratch.tiff"` would return `"scratch.tiff"`.
     - parameter path: The path to get the base name from.
     - returns: The base name of the path.
     */
    public func basename(path: String) -> String {
        return (path as NSString).lastPathComponent
    }

    /**
     Returns the directory name of the given path. For example, `"/tmp/scratch.tiff"` would return `"tmp"`.
     - parameter path: The path to get the directory name from.
     - returns: The directory name of the path.
     */
    public func dirname(path: String) -> String {
        guard path != "" else { return "" }

        let components = (path as NSString).pathComponents
        return components.count == 1 ? components[0] : components[components.count - 2]
    }

    /**
     Returns the name of a file without the extension. For example, `"/tmp/scratch.tiff"` would return `"scratch"`.
     - parameter path: The path of the file to get the name of.
     - returns: The name of the file.
     */
    public func filename(path: String) -> String {
        let baseName = basename(path: path)
        return (baseName as NSString).deletingPathExtension
    }

    /**
     Returns the extension of a file. For example,`"/tmp/scratch.tiff"` would return `"tiff"`.
     - parameter path: The path of the file to get the extension of.
     - returns: The extension of the file.
     */
    public func `extension`(path: String) -> String {
        let baseName = basename(path: path)
        return (baseName as NSString).pathExtension
    }

    /**
     Checks if an item at the given path exists.
     - parameter path: The path at which to check.
     - returns: `true` if an item exists at that path, `false` otherwise.
     */
    public func exists(path: String) -> Bool {
        return manager.fileExists(atPath: expand(path: path))
    }

    /**
     Checks if the given path is a directory.
     - parameter path: The path to check.
     - returns: `true` if the path exists and is a directory, `false` otherwise.
     */
    public func isDir(path: String) -> Bool {
        var dir: ObjCBool = false
        let exists = manager.fileExists(atPath: expand(path: path), isDirectory: &dir)

        return exists && dir.boolValue
    }

    /**
     Checks if the given path is a file.
     - parameter path: The path to check.
     - returns: `true` if the path exists and is a file, `false` otherwise.
     */
    public func isFile(path: String) -> Bool {
        var dir: ObjCBool = false
        let exists = manager.fileExists(atPath: expand(path: path), isDirectory: &dir)

        return exists && !dir.boolValue
    }

    /**
     Copies an item to a new location.
     - parameter path: The path of the item to copy.
     - parameter newPath: The path to copy the item to.
     */
    public func copy(from path: String, to newPath: String) throws {
        try manager.copyItem(atPath: expand(path: path), toPath: expand(path: newPath))
    }

    /**
     Moves an item to a new location.
     - parameter oldPath: The path of the item to move.
     - parameter newPath: The path to move the item to.
     */
    public func move(from oldPath: String, to newPath: String) throws {
        try manager.moveItem(atPath: expand(path: oldPath), toPath: expand(path: newPath))
    }

    /**
     Renames the the given item.

     **NOTE:** If the item is a file, this method will preserve the file extension.
     If you wish to change the file extension use the `move()` method instead.
     - parameter oldName: The path of the item to rename.
     - parameter newName: The new name to give the item. If a path is given only the base will be used.
     */
    public func rename(from oldName: String, to newName: String) throws {
        let oldPath = expand(path: oldName)
        var name = expand(path: newName)

        if isFile(path: oldPath) {
            let ext = `extension`(path: oldPath)
            let fileName = filename(path: name)

            name = "\(fileName).\(ext)"
        }

        try manager.moveItem(atPath: oldPath, toPath: name)
    }

    /**
     Removes the item at the given path.
     - parameter path: The path of the item to remove.
     */
    public func remove(path: String) throws {
        try manager.removeItem(atPath: path)
    }

    /**
     Creates a new directory at the given path. If there are intermediate directories that do not exist this method will throw and error.
     - parameter path: The path at which to create the directory.
     - parameter attributes: A dictionary of attributes to apply to the directory. Defaults to `nil`.
     */
    public func mkdir(path: String, attributes: [FileAttributeKey: Any]? = nil) throws {
        try manager.createDirectory(atPath: expand(path: path), withIntermediateDirectories: false, attributes: attributes)
    }

    /**
     Creates a new directory at the given path. This method will also create any necessary intermediate directories if they do not exist. Like `mkdir -p`.
     - parameter path: The path at which to create the directory.
     - parameter attributes: A dictionary of attributes to apply to the directory. Defaults to `nil`.
     */
    public func mkdirp(path: String, attributes: [FileAttributeKey: Any]? = nil) throws {
        try manager.createDirectory(atPath: expand(path: path), withIntermediateDirectories: true, attributes: attributes)
    }

    /**
     Creates an empty file at the given path.

     **Note:** This method will overwrite the file if it exists. If you do not wish to overwrite the file use the `ensureFile()` method instead.
     - parameter path: The path at which to create the file.
     - parameter attributes: A dictionary of attributes to apply to the file. Defaults to `nil`.
     */
    @discardableResult
    public func create(path: String, attributes: [FileAttributeKey: Any]? = nil) -> Bool {
        return manager.createFile(atPath: expand(path: path), contents: nil, attributes: attributes)
    }

    /**
     Ensures that a directory at the given path exists. If it does not exist, it is created along with any necessary intermediate paths.
     - parameter path: The path of the directory.
     - parameter attributes: A dictionary of attributes to apply to the directory if it is created. Defaults to `nil`.
     - returns: `true` if the directory already exists, `false` otherwise.
     */
    @discardableResult
    public func ensureDir(path: String, attributes: [FileAttributeKey: Any]? = nil) throws -> Bool {
        let dir = expand(path: path)

        if exists(path: dir) {
            return true
        }

        try mkdirp(path: dir, attributes: attributes)
        return false
    }

    /**
     Ensures that a file at the given path exists. If it does not exists, it is created.
     - parameter path: The path of the file.
     - parameter attributes: A dictionary of attributes to apply to the file if it is created. Defaults to `nil`.
     - returns: `true` if the file already exists or was successfully created. `false` if the directory does not exist and was not created.
     */
    @discardableResult
    public func ensureFile(path: String, attributes: [FileAttributeKey: Any]? = nil) throws -> Bool {
        let file = expand(path: path)

        if exists(path: file) {
            return true
        }

        let didSucceed = create(path: file, attributes: attributes)

        if !didSucceed {
            throw Error.fileCreationFailed
        }

        return false
    }

    /**
     Ensures the directory at the given path is empty. If it is not empty, the contents are deleted.
     If the directory does not exist, it is created.
     */
    public func emptyDir(path: String) throws {
        let dir = expand(path: path)

        guard try ensureDir(path: dir) else { return }

        let contents = try manager.contentsOfDirectory(atPath: dir)

        for item in contents {
            try manager.removeItem(atPath: item)
        }
    }

    /**
     Reads the file at the given path.
     - parameter path: The path of the file to read.
     - returns: A `Data` object with the contents of the file.
     */
    public func readFile(path: String) throws -> Data {
        let file = expand(path: path)

        guard let data = manager.contents(atPath: file) else {
            throw Error.readFailed
        }

        return data
    }

    /**
     Writes the given data to a file.
     - parameter path: The path of the file to write to.
     - parameter data: The data to write to the file.
     */
    public func writeFile(path: String, data: Data) throws {
        let file = expand(path: path)

        do {
            try data.write(to: URL(fileURLWithPath: file))
        } catch {
            throw Error.writeFailed
        }
    }

    /**
     Reads a file at the given path and parses it as JSON. The JSON is decoded into a type conforming to the `Decodable` protocol.
     - parameter path: The path of the file to read.
     - parameter type: A type conforming to `Decodable` to parse the JSON as.
     - returns: An instance of the given type.
     */
    public func readJSON<T: Decodable>(path: String, type _: T.Type) throws -> T {
        let data = try readFile(path: path)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /**
     Reads a file at the given path and parses it as raw JSON.
     - parameter path: The path of the file to read.
     - returns: The deserialized JSON.
     */
    public func readJSON(path: String) throws -> Any {
        let data = try readFile(path: path)
        return try JSONSerialization.jsonObject(with: data)
    }

    /**
     Takes an object that conforms to the `Encodable` protocol and writes it to a file as JSON.
     - parameter path: The path of the file to write to.
     - parameter object: The object to encode as json.
     */
    public func writeJSON<T: Encodable>(path: String, object: T) throws {
        let data = try JSONEncoder().encode(object)
        try writeFile(path: path, data: data)
    }

    /**
     Writes an object to a file as raw JSON.
     - parameter path: THe path of the file to write to.
     - parameter object: The object to convert to JSON.
     - parameter options: An optional array of writing options for the JSON serialization.
     */
    public func writeJSON(path: String, object: Any, options: JSONSerialization.WritingOptions = []) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: options)
        try writeFile(path: path, data: data)
    }
}
