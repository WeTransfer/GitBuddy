//
//  Main.swift
//  ChangelogProducer
//
//  Created by Antoine van der Lee on 16/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import ChangelogProducerCore

do {
    let changelogProducer = try ChangelogProducer()
    try changelogProducer.run()
} catch {
    print("Whoops! An error occurred: \(error)")
}
