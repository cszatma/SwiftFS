//
//  FSManager.swift
//  SwiftFS
//
//  Created by Christopher Szatmary on 2019-08-31.
//

import Foundation

public protocol FSManager {
    func fileExists(atPath path: String) -> Bool

    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool

    func copyItem(atPath srcPath: String, toPath dstPath: String) throws

    func moveItem(atPath srcPath: String, toPath dstPath: String) throws

    func removeItem(atPath path: String) throws

    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws

    func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey: Any]?) -> Bool

    func contentsOfDirectory(atPath path: String) throws -> [String]

    func contents(atPath path: String) -> Data?
}

extension FileManager: FSManager {}
