//
//  ContentView.swift
//  HelloT
//
//  Created by Jingyu Du on 2026/6/7.
//

import SwiftUI

// MARK: - Data Models

struct CityClock: Identifiable {
    let id = UUID()
    let name: String
    let timeZone: TimeZone
    let flag: String
}

let cities = [
    CityClock(name: "北京", timeZone: TimeZone(identifier: "Asia/Shanghai")!, flag: "🇨🇳"),
    CityClock(name: "纽约", timeZone: TimeZone(identifier: "America/New_York")!, flag: "🇺🇸"),
    CityClock(name: "巴黎", timeZone: TimeZone(identifier: "Europe/Paris")!, flag: "🇫🇷"),
    CityClock(name: "东京", timeZone: TimeZone(identifier: "Asia/Tokyo")!, flag: "🇯🇵"),
]

// MARK: - Flat accent colors for each city
let cityAccents: [Color] = [.blue, .orange, .purple, .pink]

// MARK: - Main View

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("isFlatUI") private var isFlatUI = false

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case 0:
                    WorldClockView(isDarkMode: isDarkMode, isFlatUI: isFlatUI)
                case 1:
                    StopwatchView(isDarkMode: isDarkMode, isFlatUI: isFlatUI)
                case 2:
                    SystemView(isDarkMode: $isDarkMode, isFlatUI: $isFlatUI)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom tab bar
            HStack(spacing: 0) {
                TabButton(title: "时钟", icon: "clock.fill", selected: selectedTab == 0, isFlatUI: isFlatUI) {
                    selectedTab = 0
                }
                TabButton(title: "秒表", icon: "stopwatch.fill", selected: selectedTab == 1, isFlatUI: isFlatUI) {
                    selectedTab = 1
                }
                TabButton(title: "系统", icon: "gearshape.fill", selected: selectedTab == 2, isFlatUI: isFlatUI) {
                    selectedTab = 2
                }
            }
            .padding(.top, isFlatUI ? 0 : 6)
            .padding(.bottom, 20)
            .background {
                if isFlatUI {
                    Color(UIColor.systemBackground)
                } else {
                    Color(isDarkMode ? UIColor.systemGray6 : UIColor.white)
                        .shadow(color: .black.opacity(0.1), radius: 3, y: -2)
                }
            }
            .overlay(alignment: .top) {
                if isFlatUI {
                    Rectangle()
                        .fill(Color(UIColor.separator))
                        .frame(height: 0.5)
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let selected: Bool
    let isFlatUI: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selected ? Color.accentColor : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                isFlatUI && selected
                    ? Color.accentColor.opacity(0.1)
                    : Color.clear
            )
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

    var body: some View {
        ScrollView {
            if isFlatUI {
                // Flat: single column list
                LazyVStack(spacing: 0) {
                    ForEach(Array(cities.enumerated()), id: \.offset) { index, city in
                        FlatClockRow(
                            city: city,
                            date: now,
                            index: index,
                            isExpanded: selectedIndex == index
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                selectedIndex = selectedIndex == index ? nil : index
                            }
                        }
                        if index < cities.count - 1 {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
                .padding(.vertical, 8)
            } else {
                // Default: 2x2 grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(Array(cities.enumerated()), id: \.offset) { index, city in
                        ClockFaceView(
                            city: city,
                            date: now,
                            isExpanded: selectedIndex == index,
                            isDarkMode: isDarkMode
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedIndex = selectedIndex == index ? nil : index
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .onReceive(timer) { time in
            now = time
        }
    }
}

// MARK: - Flat Clock Row

struct FlatClockRow: View {
    let city: CityClock
    let date: Date
    let index: Int
    let isExpanded: Bool

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = city.timeZone
        return cal
    }

    private var hour: Int { calendar.component(.hour, from: date) }
    private var minute: Int { calendar.component(.minute, from: date) }
    private var second: Int { calendar.component(.second, from: date) }

    private var timeString: String {
        let fmt = DateFormatter()
        fmt.timeZone = city.timeZone
        fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: date)
    }

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.timeZone = city.timeZone
        fmt.dateFormat = "MM/dd EEE"
        fmt.locale = Locale(identifier: "zh_CN")
        return fmt.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Colored indicator bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(cityAccents[index])
                    .frame(width: 4, height: 36)

                // Flag
                Text(city.flag)
                    .font(.title2)

                // City + date
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .font(.body.bold())
                    Text(dateString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Time
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

            // Expanded: digital detail
            if isExpanded {
                VStack(spacing: 8) {
                    HStack(spacing: 24) {
                        VStack(spacing: 2) {
                            Text("时")
                                .font(.caption2).foregroundColor(.secondary)
                            Text("\(hour)")
                                .font(.system(size: 32, weight: .thin, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)

                        Text(":")
                            .font(.system(size: 28, weight: .thin))
                            .foregroundColor(.secondary)

                        VStack(spacing: 2) {
                            Text("分")
                                .font(.caption2).foregroundColor(.secondary)
                            Text(String(format: "%02d", minute))
                                .font(.system(size: 32, weight: .thin, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)

                        Text(":")
                            .font(.system(size: 28, weight: .thin))
                            .foregroundColor(.secondary)

                        VStack(spacing: 2) {
                            Text("秒")
                                .font(.caption2).foregroundColor(.secondary)
                            Text(String(format: "%02d", second))
                                .font(.system(size: 32, weight: .thin, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            isExpanded ? cityAccents[index].opacity(0.06) : Color.clear
        )
    }
}

// MARK: - Analog Clock Face (default style)

struct ClockFaceView: View {
    let city: CityClock
    let date: Date
    let isExpanded: Bool
    let isDarkMode: Bool

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = city.timeZone
        return cal
    }

    private var hour: Int { calendar.component(.hour, from: date) }
    private var minute: Int { calendar.component(.minute, from: date) }
    private var second: Int { calendar.component(.second, from: date) }

    private var hourAngle: Double {
        Double(hour % 12) * 30 + Double(minute) * 0.5
    }
    private var minuteAngle: Double {
        Double(minute) * 6 + Double(second) * 0.1
    }
    private var secondAngle: Double {
        Double(second) * 6
    }

    private var timeString: String {
        let fmt = DateFormatter()
        fmt.timeZone = city.timeZone
        fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: date)
    }

    private var faceColor: Color { isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.04) }
    private var rimColor: Color { isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.12) }
    private var handColor: Color { isDarkMode ? .white : .black }
    private var textColor: Color { isDarkMode ? .white : .black }

    var body: some View {
        VStack(spacing: isExpanded ? 12 : 8) {
            Text(city.flag)
                .font(isExpanded ? .system(size: 36) : .system(size: 24))

            ZStack {
                Circle()
                    .fill(faceColor)
                    .overlay(Circle().stroke(rimColor, lineWidth: 2))

                ForEach(0..<12) { i in
                    Rectangle()
                        .fill(i % 3 == 0 ? handColor.opacity(0.8) : handColor.opacity(0.35))
                        .frame(width: i % 3 == 0 ? 2.5 : 1.5,
                               height: i % 3 == 0 ? 12 : 7)
                        .offset(y: -((isExpanded ? 80 : 52) - (i % 3 == 0 ? 14 : 9)))
                        .rotationEffect(.degrees(Double(i) * 30))
                }

                Rectangle()
                    .fill(handColor)
                    .frame(width: 3.5, height: isExpanded ? 44 : 28)
                    .offset(y: -(isExpanded ? 22 : 14))
                    .rotationEffect(.degrees(hourAngle))

                Rectangle()
                    .fill(handColor.opacity(0.85))
                    .frame(width: 2.5, height: isExpanded ? 60 : 38)
                    .offset(y: -(isExpanded ? 30 : 19))
                    .rotationEffect(.degrees(minuteAngle))

                Rectangle()
                    .fill(Color.red)
                    .frame(width: 1.2, height: isExpanded ? 65 : 42)
                    .offset(y: -(isExpanded ? 32 : 21))
                    .rotationEffect(.degrees(secondAngle))

                Circle()
                    .fill(Color.red)
                    .frame(width: 5, height: 5)
            }
            .frame(width: isExpanded ? 180 : 120, height: isExpanded ? 180 : 120)

            Text(city.name)
                .font(isExpanded ? .title3.bold() : .subheadline.bold())
                .foregroundColor(textColor)

            Text(timeString)
                .font(isExpanded ? .body : .caption)
                .foregroundColor(textColor.opacity(0.5))
                .monospacedDigit()
        }
        .padding(isExpanded ? 16 : 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color.white.opacity(isExpanded ? 0.12 : 0.06) : Color.black.opacity(isExpanded ? 0.06 : 0.03))
        )
        .scaleEffect(isExpanded ? 1.0 : 0.88)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
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

    private var textColor: Color { isDarkMode ? .white : .black }

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
        if history.count > 10 {
            history = Array(history.prefix(10))
        }
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
            // Display
            if isFlatUI {
                HStack(spacing: 4) {
                    let m = Int(elapsed) / 60
                    let s = Int(elapsed) % 60
                    let ms = Int((elapsed.truncatingRemainder(dividingBy: 1)) * 100)

                    Text(String(format: "%02d", m))
                        .font(.system(size: 64, weight: .thin, design: .monospaced))
                    Text(":")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.secondary)
                    Text(String(format: "%02d", s))
                        .font(.system(size: 64, weight: .thin, design: .monospaced))
                    Text(".")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.secondary)
                    Text(String(format: "%02d", ms))
                        .font(.system(size: 40, weight: .thin, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(textColor)
                .padding(.top, 50)
            } else {
                Text(display)
                    .font(.system(size: 64, weight: .thin, design: .monospaced))
                    .foregroundColor(textColor)
                    .padding(.top, 50)
            }

            // Controls
            HStack(spacing: 40) {
                Button {
                    if running {
                        laps.insert(elapsed, at: 0)
                    } else {
                        elapsed = 0
                        laps.removeAll()
                    }
                } label: {
                    if isFlatUI {
                        Text(running ? "计次" : "重置")
                            .font(.body.bold())
                            .foregroundColor(textColor)
                            .frame(width: 76, height: 44)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    } else {
                        Circle()
                            .fill(textColor.opacity(0.15))
                            .frame(width: 76, height: 76)
                            .overlay(
                                Text(running ? "圈" : "重置")
                                    .foregroundColor(textColor)
                                    .font(.body.bold())
                            )
                    }
                }

                Button {
                    if running {
                        // Stop — save to history
                        timer?.invalidate()
                        timer = nil
                        if elapsed > 0 {
                            saveToHistory(elapsed)
                        }
                    } else {
                        let start = Date().addingTimeInterval(-elapsed)
                        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                            elapsed = Date().timeIntervalSince(start)
                        }
                    }
                    running.toggle()
                } label: {
                    if isFlatUI {
                        Text(running ? "停止" : "开始")
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .frame(width: 76, height: 44)
                            .background(running ? Color.red : Color.green)
                            .cornerRadius(10)
                    } else {
                        Circle()
                            .fill(running ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                            .frame(width: 76, height: 76)
                            .overlay(
                                Text(running ? "停止" : "开始")
                                    .foregroundColor(.white)
                                    .font(.body.bold())
                            )
                    }
                }
            }
            .padding(.top, 12)

            // Laps + History list
            List {
                // Current laps
                if !laps.isEmpty {
                    Section {
                        ForEach(Array(laps.enumerated()), id: \.offset) { i, lap in
                            HStack {
                                Text("圈 \(laps.count - i)")
                                    .font(isFlatUI ? .caption : .body)
                                    .foregroundColor(isFlatUI ? .secondary : textColor.opacity(0.6))
                                Spacer()
                                Text(formattedTime(lap))
                                    .foregroundColor(textColor)
                                    .monospacedDigit()
                                    .font(isFlatUI ? .system(.body, design: .monospaced) : .body)
                            }
                            .listRowBackground(
                                isFlatUI ? Color.clear : textColor.opacity(0.05)
                            )
                        }
                    } header: {
                        ListSectionHeader(title: "本次计次", icon: "flag.fill", isFlatUI: isFlatUI)
                    }
                }

                // History
                if !history.isEmpty {
                    Section {
                        ForEach(Array(history.enumerated()), id: \.element.id) { i, record in
                            HStack {
                                // Rank badge
                                Text("#\(i + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, alignment: .leading)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(formattedTime(record.duration))
                                        .foregroundColor(textColor)
                                        .monospacedDigit()
                                        .font(.system(.body, design: .monospaced))
                                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // Duration comparison bar
                                if let maxDur = history.map(\.duration).max(), maxDur > 0 {
                                    Capsule()
                                        .fill(Color.accentColor.opacity(0.3))
                                        .frame(width: max(12, CGFloat(record.duration / maxDur) * 60), height: 6)
                                }
                            }
                            .listRowBackground(
                                isFlatUI ? Color.clear : textColor.opacity(0.05)
                            )
                        }
                        .onDelete { indexSet in
                            history.remove(atOffsets: indexSet)
                            if let data = try? JSONEncoder().encode(history) {
                                UserDefaults.standard.set(data, forKey: "stopwatch_history")
                            }
                        }
                    } header: {
                        ListSectionHeader(title: "历史记录 (最近\(history.count)次)", icon: "clock.arrow.circlepath", isFlatUI: isFlatUI)
                    }
                    // Clear all button
                    Section {
                        Button(role: .destructive) {
                            withAnimation {
                                history.removeAll()
                                UserDefaults.standard.removeObject(forKey: "stopwatch_history")
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("清除全部历史记录")
                                    .font(.subheadline)
                                Spacer()
                            }
                            .frame(height: 36)
                        }
                        .listRowBackground(Color(UIColor.secondarySystemBackground).opacity(0.5))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .onAppear {
            loadHistory()
        }
    }
}

// MARK: - List Section Header

struct ListSectionHeader: View {
    let title: String
    let icon: String
    let isFlatUI: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(.caption)
        }
        .foregroundColor(.secondary)
    }
}

// MARK: - System Settings

struct SystemView: View {
    @Binding var isDarkMode: Bool
    @Binding var isFlatUI: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("系统设置")
                .font(.title2.bold())
                .padding(.top, 40)
                .padding(.bottom, 24)

            VStack(spacing: 0) {
                // Dark mode toggle
                HStack {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .font(.title2)
                        .foregroundColor(isDarkMode ? .indigo : .orange)
                        .frame(width: 36)

                    Text("外观模式")
                        .font(.body)

                    Spacer()

                    Text(isDarkMode ? "深色" : "浅色")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

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

                    Text("扁平化风格")
                        .font(.body)

                    Spacer()

                    Text(isFlatUI ? "开" : "关")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Toggle("", isOn: $isFlatUI)
                        .labelsHidden()
                        .tint(.teal)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal, 20)

            // Description
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(isFlatUI ? "当前：扁平化风格" : "当前：经典风格")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(isFlatUI
                     ? "使用简洁的列表式布局，去除阴影和圆形按钮，以纯色色块和线条为主要视觉元素。"
                     : "使用模拟表盘和圆形按钮，带有阴影和半透明效果的经典设计。"
                )
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
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
