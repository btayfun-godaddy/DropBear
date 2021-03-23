//
//  RunningRobot+TabItemRobot.swift
//  DropBear
//
//  Created by Ian Keen on 2021-03-11.
//  Copyright © 2021 Timberlane Labs. All rights reserved.
//

import DropBearSupport
import XCTest

public protocol TabItemHierarchy {
    associatedtype Configuration: TestConfigurationSource
    associatedtype ViewHierarchy
    associatedtype Current: Robot

    typealias TabController = RunningRobot<Configuration, ViewHierarchy, Current>

    var tabController: TabController { get }
}

public struct TabItem<Configuration: TestConfigurationSource, Parent, Current: Robot>: TabItemHierarchy, TabBarHierarchy {
    public let parent: Parent
    public let tabController: RunningRobot<Configuration, Parent, Current>
}

extension RunningRobot where ViewHierarchy: TabBarHierarchy {
    public typealias TabItemRobot<Next: Robot> = RunningRobot<
        Configuration,
        TabItem<Configuration, ViewHierarchy, Current>,
        Next
    >
}

extension RunningRobot.NextRobotAction where ViewHierarchy: TabBarHierarchy {
    public struct TabItemLookup {
        let tabItem: (_ tabBar: XCUIElement) -> XCUIElement

        public static func item(_ index: Int, file: StaticString = #file, line: UInt = #line) -> TabItemLookup {
            return .init { tabBar in
                if index < 0 || index >= tabBar.buttons.count {
                    XCTFail("Invalid tab index. Value should be between 0 and \(tabBar.buttons.count - 1)", file: file, line: line)
                }

                return tabBar.buttons.element(boundBy: index)
            }
        }

        public static func item(_ element: Current.Element, file: StaticString = #file, line: UInt = #line) -> TabItemLookup {
            return .init { tabBar in
                return tabBar.buttons[element.rawValue]
            }
        }
    }

    /// Used to put the _next_ `Robot` into a tab item
    public static func tab(
        _ lookup: TabItemLookup,
        file: StaticString = #file, line: UInt = #line
    ) -> RunningRobot.NextRobotAction<TabItem<Configuration, ViewHierarchy, Current>, Next> {
        return .init(
            actions: { robot in
                let tabBar = robot.source.tabBars.firstMatch

                if tabBar.buttons.count == 0 {
                    XCTFail("Unable to find any tab buttons", file: file, line: line)
                }

                let tabItem = lookup.tabItem(robot.source)

                tabItem.tap()
            },
            hierarchy: { .init(parent: $0.viewHierarchy, tabController: $0) },
            next: Next.init
        )
    }
}

extension RunningRobot where ViewHierarchy: TabItemHierarchy {
    public func backToTabBarController() -> ViewHierarchy.TabController {
        return viewHierarchy.tabController
    }
}