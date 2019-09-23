//
//  MockFileManagerTests.swift
//  MockFSTests
//
//  Created by Christopher Szatmary on 2019-09-01.
//

import Foundation
@testable import MockFS
import Nimble
import Quick

final class MockFileManagerTests: QuickSpec {
    override func spec() {
        describe("MockFileManager.swift tests") {
            var mockFileManager: MockFileManager!

            beforeEach {
                mockFileManager = MockFileManager(json: [
                    "home": [
                        "README.md": "# Home",
                        "dev": [
                            "index.js": "console.log('hello');",
                        ],
                    ],
                    "bin": [
                        "hello.sh": "echo hello",
                    ],
                ])
            }

            describe("cd)") {
                it("changes the current directory to a subdirectory") {
                    try! mockFileManager.cd(toPath: "home/dev")

                    expect(mockFileManager.pwd()).to(equal("/home/dev"))
                }

                it("changes to a directory with an absolute path") {
                    try! mockFileManager.cd(toPath: "/bin")

                    expect(mockFileManager.pwd()).to(equal("/bin"))
                }

                it("changes to a parent directory") {
                    try! mockFileManager.cd(toPath: "home/dev")
                    try! mockFileManager.cd(toPath: "..")

                    expect(mockFileManager.pwd()).to(equal("/home"))
                }

                it("it remains in root when changing to the parent directory") {
                    try! mockFileManager.cd(toPath: "..")

                    expect(mockFileManager.pwd()).to(equal("/"))
                }

                it("throws an nodeNotFound error if the path doesn't exist") {
                    expect { try mockFileManager.cd(toPath: "/notadir") }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.nodeNotFound(name: "/notadir")))
                    })
                }
            }

            // MARK: - FSManager

            describe("fileExists") {
                it("returns true when the file exists") {
                    let exists = mockFileManager.fileExists(atPath: "/home/dev/index.js")
                    expect(exists).to(beTrue())
                }

                it("returns false when the file does not exist") {
                    let exists = mockFileManager.fileExists(atPath: "/home/dev/main.ts")
                    expect(exists).to(beFalse())
                }

                it("sets isDirectory to true when the path is a directory") {
                    var isDirectory: ObjCBool = false
                    let exists = mockFileManager.fileExists(
                        atPath: "/home/dev",
                        isDirectory: &isDirectory
                    )

                    expect(exists).to(beTrue())
                    expect(isDirectory.boolValue).to(beTrue())
                }

                it("sets isDirectory to false when the path is not a directory") {
                    var isDirectory: ObjCBool = false
                    let exists = mockFileManager.fileExists(
                        atPath: "/home/dev/index.js",
                        isDirectory: &isDirectory
                    )

                    expect(exists).to(beTrue())
                    expect(isDirectory.boolValue).to(beFalse())
                }
            }

            describe("copyItem") {
                it("copies the file to the given path") {
                    let originalPath = "/bin/hello.sh"
                    let copiedPath = "/home/dev/index.sh"
                    try! mockFileManager.copyItem(atPath: originalPath, toPath: copiedPath)

                    expect(mockFileManager.fileExists(atPath: originalPath)).to(beTrue())
                    expect(mockFileManager.fileExists(atPath: copiedPath)).to(beTrue())

                    let original = mockFileManager.contents(atPath: originalPath)!
                    let copied = mockFileManager.contents(atPath: copiedPath)!

                    expect(original).to(equal(copied))
                }

                it("copies the directory to the given path") {
                    let originalPath = "/bin"
                    let copiedPath = "/home/bin"
                    try! mockFileManager.copyItem(atPath: originalPath, toPath: copiedPath)

                    var isDir: ObjCBool = false
                    expect(mockFileManager.fileExists(atPath: originalPath)).to(beTrue())
                    expect(mockFileManager.fileExists(atPath: copiedPath, isDirectory: &isDir)).to(beTrue())
                    expect(isDir.boolValue).to(beTrue())
                    expect(mockFileManager.fileExists(atPath: "\(copiedPath)/hello.sh")).to(beTrue())

                    let original = mockFileManager.contents(atPath: "\(originalPath)/hello.sh")!
                    let copied = mockFileManager.contents(atPath: "\(copiedPath)/hello.sh")!
                    expect(original).to(equal(copied))
                }

                it("throws an error if srcPath doesn't exist") {
                    expect { try mockFileManager.copyItem(atPath: "/notadir", toPath: "/home") }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.nodeNotFound(name: "/notadir")))
                    })
                }

                it("throws an error if dstPath is an invalid path") {
                    expect { try mockFileManager.copyItem(atPath: "/bin/hello.sh", toPath: "/notadir") }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.invalidPath))
                    })
                }

                it("throws an error if an item already exists at dstPath") {
                    expect { try mockFileManager.copyItem(atPath: "/bin/hello.sh", toPath: "/home/dev") }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.nodeExists))
                    })
                }
            }

            describe("moveItem") {
                it("moves the file to the given path") {
                    let originalPath = "/bin/hello.sh"
                    let movedPath = "/home/dev/index.sh"
                    let original = mockFileManager.contents(atPath: originalPath)!
                    try! mockFileManager.moveItem(atPath: originalPath, toPath: movedPath)

                    expect(mockFileManager.fileExists(atPath: originalPath)).to(beFalse())
                    expect(mockFileManager.fileExists(atPath: movedPath)).to(beTrue())

                    let moved = mockFileManager.contents(atPath: movedPath)!

                    expect(original).to(equal(moved))
                }

                it("moves the directory to the given path") {
                    let originalPath = "/bin"
                    let movedPath = "/home/bin"
                    let original = mockFileManager.contents(atPath: "\(originalPath)/hello.sh")!
                    try! mockFileManager.moveItem(atPath: originalPath, toPath: movedPath)

                    var isDir: ObjCBool = false
                    expect(mockFileManager.fileExists(atPath: originalPath)).to(beFalse())
                    expect(mockFileManager.fileExists(atPath: movedPath, isDirectory: &isDir)).to(beTrue())
                    expect(isDir.boolValue).to(beTrue())
                    expect(mockFileManager.fileExists(atPath: "\(movedPath)/hello.sh")).to(beTrue())

                    let moved = mockFileManager.contents(atPath: "\(movedPath)/hello.sh")!
                    expect(original).to(equal(moved))
                }

                it("throws an error if srcPath doesn't exist") {
                    expect { try mockFileManager.moveItem(atPath: "/notadir", toPath: "/home") }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.nodeNotFound(name: "/notadir")))
                    })
                }

                it("throws an error if dstPath is an invalid path") {
                    expect { try mockFileManager.moveItem(atPath: "/bin/hello.sh", toPath: "/notadir") }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.invalidPath))
                    })
                }

                it("throws an error if an item already exists at dstPath") {
                    expect { try mockFileManager.moveItem(atPath: "/bin/hello.sh", toPath: "/home/dev") }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.nodeExists))
                    })
                }
            }

            describe("removeItem") {
                it("removes the file to the given path") {
                    let path = "/bin/hello.sh"
                    try! mockFileManager.removeItem(atPath: path)

                    expect(mockFileManager.fileExists(atPath: path)).to(beFalse())
                }

                it("removes the directory to the given path") {
                    let path = "/bin"
                    try! mockFileManager.removeItem(atPath: path)

                    expect(mockFileManager.fileExists(atPath: path)).to(beFalse())
                }

                it("throws an error if path doesn't exist") {
                    expect { try mockFileManager.removeItem(atPath: "/notadir") }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.nodeNotFound(name: "/notadir")))
                    })
                }
            }

            describe("createDirectory") {
                it("creates a directory at the given path") {
                    let path = "/home/documents"
                    try! mockFileManager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)

                    var isDir: ObjCBool = false
                    expect(mockFileManager.fileExists(atPath: path, isDirectory: &isDir)).to(beTrue())
                    expect(isDir.boolValue).to(beTrue())
                }

                it("creates a directory and necessary intermediate directories") {
                    let path = "/home/documents/files/swift"
                    try! mockFileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)

                    var isDir: ObjCBool = false
                    expect(mockFileManager.fileExists(atPath: path, isDirectory: &isDir)).to(beTrue())
                    expect(isDir.boolValue).to(beTrue())
                }

                it("throws an error if createIntermediates is false and an intermediate directory doesn't exist") {
                    let path = "/home/documents/files/swift"
                    expect { try mockFileManager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil) }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.nodeNotFound(name: "/home/documents")))
                    })
                }
            }

            describe("createFile") {
                it("creates a file at the given path and returns true") {
                    let path = "/home/main.ts"
                    let data = "type Optional<T> = T | undefined;".data(using: .utf8)
                    let result = mockFileManager.createFile(atPath: path, contents: data, attributes: nil)

                    expect(result).to(beTrue())
                    expect(mockFileManager.fileExists(atPath: path)).to(beTrue())

                    let fileData = mockFileManager.contents(atPath: path)!

                    expect(fileData).to(equal(data))
                }

                it("returns false if the file wasn't created") {
                    let path = "/home/dne/main.ts"
                    let data = "type Optional<T> = T | undefined;".data(using: .utf8)
                    let result = mockFileManager.createFile(atPath: path, contents: data, attributes: nil)

                    expect(result).to(beFalse())
                    expect(mockFileManager.fileExists(atPath: path)).to(beFalse())
                }
            }

            describe("contentsOfDirectory") {
                it("returns an array with the names of each item in the directory") {
                    let path = "/home"
                    let expected = ["README.md", "dev"]
                    let contents = try! mockFileManager.contentsOfDirectory(atPath: path)

                    expect(contents).to(haveCount(2))
                    expect(contents).to(contain(expected))
                }

                it("throws an error if the path doesn't exist") {
                    let path = "/dne"
                    expect { try mockFileManager.contentsOfDirectory(atPath: path) }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.nodeNotFound(name: path)))
                    })
                }

                it("throws an error if path doesn't point to a directory") {
                    let path = "/home/README.md"
                    expect { try mockFileManager.contentsOfDirectory(atPath: path) }.to(throwError { error in
                        expect(error).to(matchError(MockFileManager.Error.notADir))
                    })
                }
            }

            describe("contents") {
                it("returns the contents of the file") {
                    let path = "/home/README.md"
                    let expected = "# Home".data(using: .utf8)
                    let contents = mockFileManager.contents(atPath: path)!

                    expect(contents).to(equal(expected))
                }

                it("returns nil if the path doesn't exist") {
                    let path = "/dne"
                    let contents = mockFileManager.contents(atPath: path)

                    expect(contents).to(beNil())
                }

                it("returns nil if the path points to a directory") {
                    let path = "/home"
                    let contents = mockFileManager.contents(atPath: path)

                    expect(contents).to(beNil())
                }
            }
        }
    }
}
