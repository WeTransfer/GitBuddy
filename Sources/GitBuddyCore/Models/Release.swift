//
//  Release.swift
//  GitBuddyCore
//
//  Created by Antoine van der Lee on 05/02/2020.
//

import Foundation

/// A release that exists on GitHub.
struct Release {
    let tag: Tag
    let url: URL
    let title: String
}
