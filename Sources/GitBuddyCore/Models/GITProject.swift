//
//  GITProject.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

struct GITProject: ShellInjectable {
    let organisation: String
    let repository: String

    static func current() -> GITProject {
        /// E.g. WeTransfer/Coyote
        let projectInfo = shell.execute(.repositoryName)
            .split(separator: "/")
            .map { String($0) }

        return GITProject(organisation: String(projectInfo[0]), repository: String(projectInfo[1]))
    }
}
