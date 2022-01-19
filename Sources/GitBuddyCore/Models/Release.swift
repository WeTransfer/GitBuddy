//
//  Release.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 05/02/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

/// A release that exists on GitHub.
struct Release: Encodable {
    let tag: Tag
    let url: URL
    let title: String
    let changelog: String
}
