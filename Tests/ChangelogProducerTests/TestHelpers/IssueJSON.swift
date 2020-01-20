//
//  IssueJSON.swift
//  ChangelogProducerTests
//
//  Created by Antoine van der Lee on 10/01/2020.
//  Copyright © 2020 WeTransfer. All rights reserved.
//

import Foundation

let IssueJSON = """

{
  "url": "https://api.github.com/repos/WeTransfer/Diagnostics/issues/39",
  "repository_url": "https://api.github.com/repos/WeTransfer/Diagnostics",
  "labels_url": "https://api.github.com/repos/WeTransfer/Diagnostics/issues/39/labels{/name}",
  "comments_url": "https://api.github.com/repos/WeTransfer/Diagnostics/issues/39/comments",
  "events_url": "https://api.github.com/repos/WeTransfer/Diagnostics/issues/39/events",
  "html_url": "https://github.com/WeTransfer/Diagnostics/issues/39",
  "id": 541453394,
  "node_id": "MDU6SXNzdWU1NDE0NTMzOTQ=",
  "number": 39,
  "title": "Get warning for file 'style.css' after building",
  "user": {
    "login": "davidsteppenbeck",
    "id": 59126213,
    "node_id": "MDQ6VXNlcjU5MTI2MjEz",
    "avatar_url": "https://avatars2.githubusercontent.com/u/59126213?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/davidsteppenbeck",
    "html_url": "https://github.com/davidsteppenbeck",
    "followers_url": "https://api.github.com/users/davidsteppenbeck/followers",
    "following_url": "https://api.github.com/users/davidsteppenbeck/following{/other_user}",
    "gists_url": "https://api.github.com/users/davidsteppenbeck/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/davidsteppenbeck/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/davidsteppenbeck/subscriptions",
    "organizations_url": "https://api.github.com/users/davidsteppenbeck/orgs",
    "repos_url": "https://api.github.com/users/davidsteppenbeck/repos",
    "events_url": "https://api.github.com/users/davidsteppenbeck/events{/privacy}",
    "received_events_url": "https://api.github.com/users/davidsteppenbeck/received_events",
    "type": "User",
    "site_admin": false
  },
  "labels": [

  ],
  "state": "closed",
  "locked": false,
  "assignee": null,
  "assignees": [

  ],
  "milestone": null,
  "comments": 2,
  "created_at": "2019-12-22T13:49:30Z",
  "updated_at": "2020-01-06T08:45:18Z",
  "closed_at": "2020-01-03T13:02:59Z",
  "author_association": "NONE",
  "body": "Details are in the image. I resolved it for the time being by removing file 'style.css' from the Xcode project. (Installed Diagnostics 1.2 using Cocoapods 1.8 and Xcode)",
  "closed_by": {
    "login": "AvdLee",
    "id": 4329185,
    "node_id": "MDQ6VXNlcjQzMjkxODU=",
    "avatar_url": "https://avatars2.githubusercontent.com/u/4329185?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/AvdLee",
    "html_url": "https://github.com/AvdLee",
    "followers_url": "https://api.github.com/users/AvdLee/followers",
    "following_url": "https://api.github.com/users/AvdLee/following{/other_user}",
    "gists_url": "https://api.github.com/users/AvdLee/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/AvdLee/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/AvdLee/subscriptions",
    "organizations_url": "https://api.github.com/users/AvdLee/orgs",
    "repos_url": "https://api.github.com/users/AvdLee/repos",
    "events_url": "https://api.github.com/users/AvdLee/events{/privacy}",
    "received_events_url": "https://api.github.com/users/AvdLee/received_events",
    "type": "User",
    "site_admin": false
  }
}

"""
