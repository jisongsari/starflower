//
//  StarflowerWidgetLiveActivity.swift
//  StarflowerWidget
//
//  Created by 양지성 on 6/19/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StarflowerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct StarflowerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StarflowerWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension StarflowerWidgetAttributes {
    fileprivate static var preview: StarflowerWidgetAttributes {
        StarflowerWidgetAttributes(name: "World")
    }
}

extension StarflowerWidgetAttributes.ContentState {
    fileprivate static var smiley: StarflowerWidgetAttributes.ContentState {
        StarflowerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: StarflowerWidgetAttributes.ContentState {
         StarflowerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: StarflowerWidgetAttributes.preview) {
   StarflowerWidgetLiveActivity()
} contentStates: {
    StarflowerWidgetAttributes.ContentState.smiley
    StarflowerWidgetAttributes.ContentState.starEyes
}
