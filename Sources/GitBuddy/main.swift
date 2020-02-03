//
//  Main.swift
//  GitBuddy
//
//  Created by Antoine van der Lee on 16/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import GitBuddyCore

do {
    let gitBuddy = try GitBuddy()
    try gitBuddy.run()
} catch {
    print("Whoops! An error occurred: \(error)")
}
