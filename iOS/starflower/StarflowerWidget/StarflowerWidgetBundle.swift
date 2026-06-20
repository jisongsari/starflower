//
//  StarflowerWidgetBundle.swift
//  StarflowerWidget
//
//  Created by 양지성 on 6/19/26.
//

import WidgetKit
import SwiftUI

@main
struct StarflowerWidgetBundle: WidgetBundle {
    var body: some Widget {
        StarflowerWidget()
        StarflowerWidgetControl()
        StarflowerWidgetLiveActivity()
    }
}
