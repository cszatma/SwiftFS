import Quick

@testable import MockFSTests
@testable import SwiftFSTests

QCKMain([
    // MockFS
    FSNodeTests.self,
    MockFSTests.self,
    // SwiftFS
    SwiftFSTests.self,
])
