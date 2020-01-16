//
//  GITProject.swift
//  ChangelogProducerCore
//
//  Created by Antoine van der Lee on 16/01/2020.
//

import Foundation

struct GITProject {
    let organisation: String
    let repository: String

    static func current() -> GITProject {
        /// E.g. WeTransfer/Coyote
        let projectInfo = Shell.execute("git remote show origin -n | ruby -ne 'puts /^\\s*Fetch.*(:|\\/){1}([^\\/]+\\/[^\\/]+).git/.match($_)[2] rescue nil'")
            .split(separator: "/")
            .map { String($0).filter { !$0.isNewline } }

        return GITProject(organisation: String(projectInfo[0]), repository: String(projectInfo[1]))
    }
}
