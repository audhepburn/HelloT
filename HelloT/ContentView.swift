//
//  ContentView.swift
//  HelloT
//
//  Created by Jingyu Du on 2026/6/7.
//

import SwiftUI

// MARK: - Neumorphism Helpers

extension Color {
    static let neuBg = Color(red: 0.93, green: 0.93, blue: 0.95)
    static let neuBgDark = Color(red: 0.17, green: 0.17, blue: 0.20)
}

struct NeuShadow: ViewModifier {
    let isDark: Bool
    var radius: CGFloat = 8
    var offset: CGFloat = 6

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isDark ? .white.opacity(0.08) : .white.opacity(0.7),
                radius: radius, x: -offset, y: -offset
            )
            .shadow(
                color: isDark ? .black.opacity(0.5) : .black.opacity(0.15),
                radius: radius, x: offset, y: offset
            )
    }
}

struct NeuInset: ViewModifier {
    let isDark: Bool
    var radius: CGFloat = 6
    var offset: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isDark ? .black.opacity(0.5) : .black.opacity(0.15),
                radius: radius, x: -offset, y: -offset
            )
            .shadow(
                color: isDark ? .white.opacity(0.08) : .white.opacity(0.7),
                radius: radius, x: offset, y: offset
            )
    }
}

extension View {
    func neuRaised(isDark: Bool, radius: CGFloat = 8, offset: CGFloat = 6) -> some View {
        modifier(NeuShadow(isDark: isDark, radius: radius, offset: offset))
    }

    func neuInset(isDark: Bool, radius: CGFloat = 6, offset: CGFloat = 4) -> some View {
        modifier(NeuInset(isDark: isDark, radius: radius, offset: offset))
    }
}

// MARK: - Localization Helpers

enum AppLanguage: String, CaseIterable, Codable {
    case system = ""
    case zh = "zh-Hans"
    case en = "en"
    case de = "de"

    var displayName: String {
        switch self {
        case .system: return String(localized: "lang.system")
        case .zh: return String(localized: "lang.chinese")
        case .en: return String(localized: "lang.english")
        case .de: return String(localized: "lang.german")
        }
    }

    var locale: Locale? {
        switch self {
        case .system: return nil
        case .zh: return Locale(identifier: "zh-Hans")
        case .en: return Locale(identifier: "en")
        case .de: return Locale(identifier: "de")
        }
    }
}

// MARK: - Data Models

struct CityClock: Identifiable {
    let id = UUID()
    let nameKey: LocalizedStringResource
    let timeZone: TimeZone
    let flag: String

    var name: String { String(localized: nameKey) }
}

let cities = [
    CityClock(nameKey: "city.beijing", timeZone: TimeZone(identifier: "Asia/Shanghai")!, flag: "🇨🇳"),
    CityClock(nameKey: "city.newyork", timeZone: TimeZone(identifier: "America/New_York")!, flag: "🇺🇸"),
    CityClock(nameKey: "city.paris", timeZone: TimeZone(identifier: "Europe/Paris")!, flag: "🇫🇷"),
    CityClock(nameKey: "city.tokyo", timeZone: TimeZone(identifier: "Asia/Tokyo")!, flag: "🇯🇵"),
]

let cityAccents: [Color] = [.blue, .orange, .purple, .pink]

// MARK: - Period of Day (localized)

func periodString(for hour: Int) -> String {
    switch hour {
    case 0..<6: return String(localized: "period.dawn")
    case 6..<9: return String(localized: "period.morning")
    case 9..<12: return String(localized: "period.am")
    case 12..<14: return String(localized: "period.noon")
    case 14..<18: return String(localized: "period.afternoon")
    case 18..<19: return String(localized: "period.dusk")
    default: return String(localized: "period.evening")
    }
}

// MARK: - Main View

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isFlatUI") private var isFlatUI = false
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system

    private var bgColor: Color { isDarkMode ? .neuBgDark : .neuBg }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case 0:
                    WorldClockView(isDarkMode: isDarkMode, isFlatUI: isFlatUI)
                case 1:
                    StopwatchView(isDarkMode: isDarkMode, isFlatUI: isFlatUI)
                case 2:
                    SystemView(isDarkMode: $isDarkMode, isFlatUI: $isFlatUI, appLanguage: $appLanguage)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom tab bar
            HStack(spacing: 0) {
                TabButton(title: String(localized: "clock"), icon: "clock.fill", selected: selectedTab == 0, isDarkMode: isDarkMode) {
                    selectedTab = 0
                }
                TabButton(title: String(localized: "stopwatch"), icon: "stopwatch.fill", selected: selectedTab == 1, isDarkMode: isDarkMode) {
                    selectedTab = 1
                }
                TabButton(title: String(localized: "system"), icon: "gearshape.fill", selected: selectedTab == 2, isDarkMode: isDarkMode) {
                    selectedTab = 2
                }
            }
            .padding(.vertical, 8)
            .padding(.bottom, 16)
            .background(bgColor)
            .neuInset(isDark: isDarkMode, radius: 4, offset: 3)
        }
        .background(bgColor.ignoresSafeArea())
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environment(\.locale, appLanguage.locale ?? Locale.current)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let selected: Bool
    let isDarkMode: Bool
    let action: () -> Void

    private var bgColor: Color { isDarkMode ? .neuBgDark : .neuBg }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selected ? cityAccents[0] : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(bgColor)
                        .neuInset(isDark: isDarkMode, radius: 4, offset: 3)
                } else {
                    Color.clear
                }
            }
        }
    }
}

// MARK: - World Clock

struct WorldClockView: View {
    let isDarkMode: Bool
    let isFlatUI: Bool
    @State private var selectedIndex: Int? = nil
    @State private var now = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var bgColor: Color { isDarkMode ? .neuBgDark : .neuBg }

    var body: some View {
        ZStack {
            ScrollView {
                if isFlatUI {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(cities.enumerated()), id: \.offset) { index, city in
                            FlatClockRow(city: city, date: now, index: index, isDarkMode: isDarkMode)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                        selectedIndex = index
                                    }
                                }
                            if index < cities.count - 1 {
                                Divider().padding(.leading, 72)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(cities.enumerated()), id: \.offset) { index, city in
                            NeuClockFaceView(city: city, date: now, index: index, isDarkMode: isDarkMode)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                        selectedIndex = index
                                    }
                                }
                        }
                    }
                    .padding(16)
                }
            }

            if let idx = selectedIndex {
                ClockExpandedView(
                    city: cities[idx], index: idx, date: now,
                    isDarkMode: isDarkMode, isFlatUI: isFlatUI
                ) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        selectedIndex = nil
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onReceive(timer) { time in now = time }
    }
}

// MARK: - Neumorphic Clock Face (default)

struct NeuClockFaceView: View {
    let city: CityClock
    let date: Date
    let index: Int
    let isDarkMode: Bool

    private var bgColor: Color { isDarkMode ? .neuBgDark : .neuBg }
    private var textColor: Color { isDarkMode ? .white.opacity(0.85) : .black.opacity(0.75) }

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = city.timeZone
        return cal
    }

    private var hour: Int { calendar.component(.hour, from: date) }
    private var minute: Int { calendar.component(.minute, from: date) }
    private var second: Int { calendar.component(.second, from: date) }

    private var hourAngle: Double { Double(hour % 12) * 30 + Double(minute) * 0.5 }
    private var minuteAngle: Double { Double(minute) * 6 + Double(second) * 0.1 }
    private var secondAngle: Double { Double(second) * 6 }

    private var timeString: String {
        let fmt = DateFormatter()
        fmt.timeZone = city.timeZone
        fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: date)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(city.flag)
                .font(.system(size: 24))

            // Clock dial
            ZStack {
                Circle()
                    .fill(bgColor)
                    .neuInset(isDark: isDarkMode, radius: 5, offset: 4)

                ForEach(0..<12) { i in
                    Rectangle()
                        .fill(textColor.opacity(i % 3 == 0 ? 0.7 : 0.3))
                        .frame(width: i % 3 == 0 ? 2.5 : 1.5,
                               height: i % 3 == 0 ? 10 : 6)
                        .offset(y: -(52 - (i % 3 == 0 ? 12 : 8)))
                        .rotationEffect(.degrees(Double(i) * 30))
                }

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(textColor)
                    .frame(width: 3.5, height: 28)
                    .offset(y: -14)
                    .rotationEffect(.degrees(hourAngle))

                RoundedRectangle(cornerRadius: 1)
                    .fill(textColor.opacity(0.8))
                    .frame(width: 2.5, height: 38)
                    .offset(y: -19)
                    .rotationEffect(.degrees(minuteAngle))

                Rectangle()
                    .fill(cityAccents[index])
                    .frame(width: 1.2, height: 42)
                    .offset(y: -21)
                    .rotationEffect(.degrees(secondAngle))

                Circle()
                    .fill(cityAccents[index])
                    .frame(width: 5, height: 5)
            }
            .frame(width: 120, height: 120)

            Text(city.name)
                .font(.subheadline.bold())
                .foregroundColor(textColor)

            Text(timeString)
                .font(.caption)
                .foregroundColor(textColor.opacity(0.5))
                .monospacedDigit()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(bgColor)
        )
        .neuRaised(isDark: isDarkMode, radius: 10, offset: 7)
    }
}

// MARK: - Expanded Clock Detail

struct ClockExpandedView: View {
    let city: CityClock
    let index: Int
    let date: Date
    let isDarkMode: Bool
    let isFlatUI: Bool
    let onDismiss: () -> Void

    @Environment(\.locale) private var locale

    private var bgColor: Color { isDarkMode ? .neuBgDark : .neuBg }
    private var textColor: Color { isDarkMode ? .white.opacity(0.85) : .black.opacity(0.75) }
    private var accent: Color { cityAccents[index] }

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = city.timeZone
        return cal
    }

    private var hour: Int { calendar.component(.hour, from: date) }
    private var minute: Int { calendar.component(.minute, from: date) }
    private var second: Int { calendar.component(.second, from: date) }

    private var hourAngle: Double { Double(hour % 12) * 30 + Double(minute) * 0.5 }
    private var minuteAngle: Double { Double(minute) * 6 + Double(second) * 0.1 }
    private var secondAngle: Double { Double(second) * 6 }

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.timeZone = city.timeZone
        fmt.locale = locale
        fmt.dateStyle = .full
        return fmt.string(from: date)
    }

    private var utcOffset: String {
        let offset = city.timeZone.secondsFromGMT(for: date)
        let h = offset / 3600
        let m = abs(offset % 3600) / 60
        return m > 0 ? String(format: "UTC%+d:%02d", h, m) : String(format: "UTC%+d", h)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "chevron.down")
                    .font(.caption)
                Text("tap.close")
                    .font(.caption)
            }
            .foregroundColor(textColor.opacity(0.4))
            .padding(.top, 16)

            Spacer().frame(height: 20)

            Text(city.flag)
                .font(.system(size: 56))

            Text(city.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .padding(.top, 8)

            Text("\(periodString(for: hour)) · \(utcOffset)")
                .font(.subheadline)
                .foregroundColor(accent)
                .padding(.top, 4)

            Spacer().frame(height: 24)

            // Large clock dial
            ZStack {
                Circle()
                    .fill(bgColor)
                    .neuInset(isDark: isDarkMode, radius: 12, offset: 8)

                ForEach(1...12, id: \.self) { i in
                    Text("\(i)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(textColor.opacity(0.5))
                        .offset(y: -110)
                        .rotationEffect(.degrees(Double(i) * 30))
                        .rotationEffect(.degrees(-Double(i) * 30))
                }

                ForEach(0..<60) { i in
                    Rectangle()
                        .fill(textColor.opacity(i % 5 == 0 ? 0.5 : 0.15))
                        .frame(width: i % 5 == 0 ? 2 : 0.8, height: i % 5 == 0 ? 10 : 4)
                        .offset(y: -136)
                        .rotationEffect(.degrees(Double(i) * 6))
                }

                RoundedRectangle(cornerRadius: 2)
                    .fill(textColor)
                    .frame(width: 5, height: 68)
                    .offset(y: -34)
                    .rotationEffect(.degrees(hourAngle))

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(textColor.opacity(0.85))
                    .frame(width: 3.5, height: 95)
                    .offset(y: -47.5)
                    .rotationEffect(.degrees(minuteAngle))

                Rectangle()
                    .fill(accent)
                    .frame(width: 1.5, height: 108)
                    .offset(y: -54)
                    .rotationEffect(.degrees(secondAngle))

                Rectangle()
                    .fill(accent)
                    .frame(width: 1.5, height: 24)
                    .offset(y: 12)
                    .rotationEffect(.degrees(secondAngle))

                Circle().fill(accent).frame(width: 8, height: 8)
                Circle().fill(bgColor).frame(width: 3, height: 3)
            }
            .frame(width: 280, height: 280)

            Spacer().frame(height: 28)

            // Digital time
            HStack(spacing: 6) {
                VStack(spacing: 4) {
                    Text(String(localized: "hour")).font(.caption2).foregroundColor(textColor.opacity(0.4))
                    Text(String(format: "%02d", hour))
                        .font(.system(size: 36, weight: .thin, design: .monospaced))
                        .foregroundColor(textColor)
                        .frame(width: 54)
                }
                Text(":").font(.system(size: 30, weight: .thin)).foregroundColor(textColor.opacity(0.3)).padding(.bottom, 16)
                VStack(spacing: 4) {
                    Text(String(localized: "minute")).font(.caption2).foregroundColor(textColor.opacity(0.4))
                    Text(String(format: "%02d", minute))
                        .font(.system(size: 36, weight: .thin, design: .monospaced))
                        .foregroundColor(textColor)
                        .frame(width: 54)
                }
                Text(":").font(.system(size: 30, weight: .thin)).foregroundColor(textColor.opacity(0.3)).padding(.bottom, 16)
                VStack(spacing: 4) {
                    Text(String(localized: "second")).font(.caption2).foregroundColor(textColor.opacity(0.4))
                    Text(String(format: "%02d", second))
                        .font(.system(size: 36, weight: .thin, design: .monospaced))
                        .foregroundColor(textColor)
                        .frame(width: 54)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(bgColor)
            )
            .neuRaised(isDark: isDarkMode, radius: 8, offset: 5)

            Spacer().frame(height: 20)

            Text(dateString)
                .font(.body)
                .foregroundColor(textColor.opacity(0.5))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            bgColor.ignoresSafeArea()
                .onTapGesture { onDismiss() }
        )
    }
}

// MARK: - Flat Clock Row

struct FlatClockRow: View {
    let city: CityClock
    let date: Date
    let index: Int
    let isDarkMode: Bool

    @Environment(\.locale) private var locale

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = city.timeZone
        return cal
    }

    private var hour: Int { calendar.component(.hour, from: date) }
    private var minute: Int { calendar.component(.minute, from: date) }
    private var second: Int { calendar.component(.second, from: date) }

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.timeZone = city.timeZone
        fmt.locale = locale
        fmt.dateFormat = "MM/dd EEE"
        return fmt.string(from: date)
    }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(cityAccents[index])
                .frame(width: 4, height: 36)

            Text(city.flag).font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(city.name).font(.body.bold())
                Text(dateString).font(.caption2).foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%02d:%02d", hour, minute))
                    .font(.system(size: 28, weight: .light, design: .monospaced))
                Text(String(format: ":%02d", second))
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Stopwatch History Entry

struct StopwatchRecord: Identifiable, Codable {
    let id = UUID()
    let duration: TimeInterval
    let date: Date
}

// MARK: - Stopwatch

struct StopwatchView: View {
    let isDarkMode: Bool
    let isFlatUI: Bool
    @State private var elapsed: TimeInterval = 0
    @State private var running = false
    @State private var laps: [TimeInterval] = []
    @State private var timer: Timer?
    @State private var history: [StopwatchRecord] = []

    private var bgColor: Color { isDarkMode ? .neuBgDark : .neuBg }
    private var textColor: Color { isDarkMode ? .white.opacity(0.85) : .black.opacity(0.75) }

    private var display: String {
        let m = Int(elapsed) / 60
        let s = Int(elapsed) % 60
        let ms = Int((elapsed.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", m, s, ms)
    }

    private func formattedTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        let ms = Int((t.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", m, s, ms)
    }

    private func saveToHistory(_ duration: TimeInterval) {
        let record = StopwatchRecord(duration: duration, date: Date())
        history.insert(record, at: 0)
        if history.count > 10 { history = Array(history.prefix(10)) }
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "stopwatch_history")
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "stopwatch_history"),
           let decoded = try? JSONDecoder().decode([StopwatchRecord].self, from: data) {
            history = decoded
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(display)
                .font(.system(size: 64, weight: .thin, design: .monospaced))
                .foregroundColor(textColor)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(bgColor)
                )
                .neuRaised(isDark: isDarkMode, radius: 12, offset: 8)
                .padding(.top, 50)

            HStack(spacing: 40) {
                // Lap / Reset
                Button {
                    if running {
                        laps.insert(elapsed, at: 0)
                    } else {
                        elapsed = 0
                        laps.removeAll()
                    }
                } label: {
                    Text(running ? String(localized: "lap") : String(localized: "reset"))
                        .font(.body.bold())
                        .foregroundColor(textColor)
                        .frame(width: 76, height: 76)
                        .background(
                            Circle()
                                .fill(bgColor)
                        )
                        .neuRaised(isDark: isDarkMode, radius: 10, offset: 7)
                }

                // Start / Stop
                Button {
                    if running {
                        timer?.invalidate()
                        timer = nil
                        if elapsed > 0 { saveToHistory(elapsed) }
                    } else {
                        let start = Date().addingTimeInterval(-elapsed)
                        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                            elapsed = Date().timeIntervalSince(start)
                        }
                    }
                    running.toggle()
                } label: {
                    Text(running ? String(localized: "stop") : String(localized: "start"))
                        .font(.body.bold())
                        .foregroundColor(running ? .red : .green)
                        .frame(width: 76, height: 76)
                        .background(
                            Circle()
                                .fill(bgColor)
                        )
                        .neuRaised(isDark: isDarkMode, radius: 10, offset: 7)
                }
            }
            .padding(.top, 12)

            // Laps + History
            List {
                if !laps.isEmpty {
                    Section {
                        ForEach(Array(laps.enumerated()), id: \.offset) { i, lap in
                            HStack {
                                Text(String(localized: "lap.count \(laps.count - i)"))
                                    .foregroundColor(textColor.opacity(0.6))
                                Spacer()
                                Text(formattedTime(lap))
                                    .foregroundColor(textColor)
                                    .monospacedDigit()
                            }
                            .listRowBackground(bgColor)
                        }
                    } header: {
                        ListSectionHeader(title: String(localized: "lap.section"), icon: "flag.fill")
                    }
                }

                if !history.isEmpty {
                    Section {
                        ForEach(Array(history.enumerated()), id: \.element.id) { i, record in
                            HStack {
                                Text("#\(i + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(textColor.opacity(0.4))
                                    .frame(width: 28, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(formattedTime(record.duration))
                                        .foregroundColor(textColor)
                                        .monospacedDigit()
                                        .font(.system(.body, design: .monospaced))
                                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(textColor.opacity(0.4))
                                }
                                Spacer()
                                if let maxDur = history.map(\.duration).max(), maxDur > 0 {
                                    Capsule()
                                        .fill(cityAccents[0].opacity(0.3))
                                        .frame(width: max(12, CGFloat(record.duration / maxDur) * 60), height: 6)
                                }
                            }
                            .listRowBackground(bgColor)
                        }
                        .onDelete { indexSet in
                            history.remove(atOffsets: indexSet)
                            if let data = try? JSONEncoder().encode(history) {
                                UserDefaults.standard.set(data, forKey: "stopwatch_history")
                            }
                        }
                    } header: {
                        ListSectionHeader(title: String(localized: "history \(history.count)"), icon: "clock.arrow.circlepath")
                    }

                    Section {
                        Button(role: .destructive) {
                            withAnimation {
                                history.removeAll()
                                UserDefaults.standard.removeObject(forKey: "stopwatch_history")
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text(String(localized: "clear.history"))
                                    .font(.subheadline)
                                Spacer()
                            }
                            .frame(height: 36)
                        }
                        .listRowBackground(bgColor)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .onAppear { loadHistory() }
    }
}

// MARK: - List Section Header

struct ListSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2)
            Text(title).font(.caption)
        }
        .foregroundColor(.secondary)
    }
}

// MARK: - System Settings

struct SystemView: View {
    @Binding var isDarkMode: Bool
    @Binding var isFlatUI: Bool
    @Binding var appLanguage: AppLanguage

    private var bgColor: Color { isDarkMode ? .neuBgDark : .neuBg }
    private var textColor: Color { isDarkMode ? .white.opacity(0.85) : .black.opacity(0.75) }

    var body: some View {
        VStack(spacing: 0) {
            Text(String(localized: "system.settings"))
                .font(.title2.bold())
                .foregroundColor(textColor)
                .padding(.top, 40)
                .padding(.bottom, 24)

            // Settings card
            VStack(spacing: 0) {
                // Language selector
                HStack {
                    Image(systemName: "globe")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 36)
                    Text(String(localized: "app.language"))
                        .font(.body)
                        .foregroundColor(textColor)
                    Spacer()
                    Picker("", selection: $appLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.blue)
                }
                .padding(16)

                Divider().padding(.leading, 52)

                // Dark mode
                HStack {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .font(.title2)
                        .foregroundColor(isDarkMode ? .indigo : .orange)
                        .frame(width: 36)
                    Text(String(localized: "appearance"))
                        .font(.body)
                        .foregroundColor(textColor)
                    Spacer()
                    Text(isDarkMode ? String(localized: "dark") : String(localized: "light"))
                        .font(.subheadline)
                        .foregroundColor(textColor.opacity(0.5))
                    Toggle("", isOn: $isDarkMode)
                        .labelsHidden()
                        .tint(isDarkMode ? .indigo : .orange)
                }
                .padding(16)

                Divider().padding(.leading, 52)

                // Flat UI toggle
                HStack {
                    Image(systemName: isFlatUI ? "square.split.1x2" : "app.fill")
                        .font(.title2)
                        .foregroundColor(.teal)
                        .frame(width: 36)
                    Text(String(localized: "flat.style"))
                        .font(.body)
                        .foregroundColor(textColor)
                    Spacer()
                    Text(isFlatUI ? String(localized: "on") : String(localized: "off"))
                        .font(.subheadline)
                        .foregroundColor(textColor.opacity(0.5))
                    Toggle("", isOn: $isFlatUI)
                        .labelsHidden()
                        .tint(.teal)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(bgColor)
            )
            .neuRaised(isDark: isDarkMode, radius: 10, offset: 7)
            .padding(.horizontal, 20)

            // Description
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.4))
                    Text(isFlatUI ? String(localized: "current.flat") : String(localized: "current.neumorphism"))
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.4))
                }
                Text(isFlatUI
                     ? String(localized: "desc.flat")
                     : String(localized: "desc.neumorphism")
                )
                .font(.caption2)
                .foregroundColor(textColor.opacity(0.35))
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
