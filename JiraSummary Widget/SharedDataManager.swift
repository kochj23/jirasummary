//
//  SharedDataManager.swift
//  JiraSummary Widget
//
//  Reads widget data from the shared Application Support directory
//  Created by Jordan Koch on 2026-02-19.
//  Copyright (c) 2026 Jordan Koch. All rights reserved.
//

import Foundation

class SharedDataManager {
    static let shared = SharedDataManager()

    private let dataFileName = "widget_data.json"
    private let appSupportFolder = "JiraSummary"
    private let appGroupIdentifier = "group.com.jordankoch.jirasummary"

    private var containerURL: URL? {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return groupURL
        }
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupport.appendingPathComponent(appSupportFolder, isDirectory: true)
    }

    private var dataFileURL: URL? {
        containerURL?.appendingPathComponent(dataFileName)
    }

    private init() {}

    func loadWidgetData() -> JiraSummaryWidgetData {
        guard let url = dataFileURL,
              let data = try? Data(contentsOf: url) else {
            return JiraSummaryWidgetData()
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(JiraSummaryWidgetData.self, from: data)) ?? JiraSummaryWidgetData()
    }
}
