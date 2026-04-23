//
//  MainTabView.swift
//  ElectricalTestReportApp
//
//  Created by Jeff Chadkirk on 29/4/2025.
//

// Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = FormViewModel()
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            BrandHeaderView(title: "Electrical Test Report")

            TabView(selection: $selectedTab) {
                NavigationView { FormView(viewModel: viewModel, selectedTab: $selectedTab) }
                    .tabItem {
                        Label("Form", systemImage: "doc.text")
                    }
                    .tag(0)

                NavigationView { TestResultsPreviewView(viewModel: viewModel, selectedTab: $selectedTab) }
                    .tabItem {
                        Label("Preview", systemImage: "doc.text.magnifyingglass")
                    }
                    .tag(1)

                NavigationView { HistoryView(viewModel: viewModel, selectedTab: $selectedTab) }
                    .tabItem {
                        Label("History", systemImage: "clock")
                    }
                    .tag(2)

                NavigationView { SettingsView() }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
        }
    }
}
