//
//  FSNodeTests.swift
//  MockFSTests
//
//  Created by Christopher Szatmary on 2019-09-18.
//

import Foundation
@testable import MockFS
import Nimble
import Quick

final class FSNodeTests: QuickSpec {
    override func spec() {
        describe("FSNode.swift tests") {
            var root: FSNode!

            beforeEach {
                root = FSNode.root()
            }

            describe("append") {
                it("creates FSNodes from the JSON dictionary") {
                    let json = [
                        "home": [
                            "README.md": "# Home",
                            "dev": [
                                "index.js": "console.log('hello');",
                            ],
                        ],
                        "bin": [
                            "hello.sh": "echo hello",
                        ],
                    ]

                    root.append(json: json)

                    let home = root.contents["home"]!
                    let bin = root.contents["bin"]!

                    expect(home.isDir).to(beTrue())
                    expect(bin.isDir).to(beTrue())

                    let readme = home.contents["README.md"]!
                    let dev = home.contents["dev"]!
                    let helloSH = bin.contents["hello.sh"]!

                    expect(readme.isDir).to(beFalse())
                    expect(String(data: readme.data!, encoding: .utf8)!).to(equal("# Home"))
                    expect(dev.isDir).to(beTrue())
                    expect(helloSH.isDir).to(beFalse())
                    expect(String(data: helloSH.data!, encoding: .utf8)!).to(equal("echo hello"))

                    let indexJS = dev.contents["index.js"]!

                    expect(indexJS.isDir).to(beFalse())
                    expect(String(data: indexJS.data!, encoding: .utf8)!).to(equal("console.log('hello');"))
                }
            }

            describe("copy") {
                it("copies the file node") {
                    let node = FSNode.file(name: "example.swift", parent: root, data: "let x = 10".data(using: .utf8))
                    let copiedNode = node.copy()

                    expect(copiedNode).toNot(beIdenticalTo(node))
                    expect(copiedNode.name).to(equal(node.name))
                    expect(copiedNode.isDir).to(beFalse())
                    expect(copiedNode.data).to(equal(node.data))
                }

                it("copies the dir node and the contents") {
                    let json = [
                        "home": [
                            "README.md": "# Home",
                        ],
                    ]

                    root.append(json: json)
                    let copiedNode = root.copy()

                    expect(copiedNode).toNot(beIdenticalTo(root))

                    let home = root.contents["home"]!
                    let copiedHome = copiedNode.contents["home"]!

                    expect(copiedHome).toNot(beIdenticalTo(home))

                    let readme = home.contents["README.md"]!
                    let copiedReadme = copiedHome.contents["README.md"]!

                    expect(copiedReadme).toNot(beIdenticalTo(readme))
                    expect(copiedReadme.isDir).to(beFalse())
                    expect(copiedReadme.data).to(equal(readme.data))
                }
            }
        }
    }
}
