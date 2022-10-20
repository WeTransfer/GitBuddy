//
//  Created by Antoine van der Lee on 20/10/2022.
//  Copyright © 2022 WeTransfer. All rights reserved.
//

import Foundation

/// Ensures rich details become available when GitBuddy fails due to a failing GitHub API request.
struct OctoKitError: LocalizedError {

    let statusCode: Int
    let underlyingError: Error
    let errorDetails: String

    var errorDescription: String? {
        """
        GitHub API Request failed (StatusCode: \(statusCode)): \(errorDetails)
        Underlying error:
        \(underlyingError)
        """
    }

    init(error: Error) {
        underlyingError = error
        statusCode = error._code
        errorDetails = (error as NSError).userInfo.debugDescription
    }
}
