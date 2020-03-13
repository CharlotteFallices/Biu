//
//  Invalidation.swift
//  Biu
//
//  Created by 朱禹杭 on 2020/3/13.
//  Copyright © 2020 Akizuki Hiyako. All rights reserved.
//

import Foundation

open class SessionX{
    func finishRequestsForDeinit() {
        requestTaskMap.requests.forEach { $0.finish(error: AFError.sessionDeinitialized) }
    }
}
