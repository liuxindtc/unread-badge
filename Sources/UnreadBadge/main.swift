import AppKit
import ApplicationServices
import os
import SwiftUI
import UniformTypeIdentifiers
import UnreadBadgeCore

private let showSettingsNotification = Notification.Name("blaine.unreadbadge.show-settings")

final class BadgeAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let store = AppConfigurationStore()
    private let reader = DockBadgeReader()
    private lazy var badgePoller = BadgePollingCoordinator { [reader] dockName in
        reader.readBadge(dockName: dockName)
    }
    private var panel: FloatingPanel!
    private var statusItem: NSStatusItem!
    private var apps: [MonitoredApp] = []
    private var displaySettings = DisplaySettings()
    private var timer: Timer?
    private var panelFocused = false
    private var settingsWindow: NSWindow?
    private var badgePresentationTracker = BadgePresentationTracker()
    private var observedTopMode: TopMode?
    private var lastHandledSettingsRequest: String?
    private var hasPresentedPanel = false
    private var panelSpaceBehavior: PanelSpaceBehavior?
    private let presentationLogger = Logger(subsystem: "blaine.unreadbadge", category: "presentation")
    private var lastPresentationDiagnostic: String?

    override init() {
        super.init()
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(receivedExternalSettingsRequest), name: showSettingsNotification, object: nil, suspensionBehavior: .deliverImmediately)
    }

    deinit { DistributedNotificationCenter.default().removeObserver(self) }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        apps = store.load()
        displaySettings = store.loadDisplaySettings()
        lastHandledSettingsRequest = store.settingsWindowRequestToken
        configurePanel(); configureStatusItem(); refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.refresh() }
        showSettings()
    }

    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate() }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard InstanceLaunchPolicy.shouldShowSettingsOnReopen(hasVisibleWindows: flag) else { return false }
        showSettings()
        return true
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let image = NSImage(systemSymbolName: "bell.badge", accessibilityDescription: "未读消息")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleProportionallyDown
        statusItem.autosaveName = "UnreadBadgeStatusItem"
        statusItem.isVisible = true
        let menu = NSMenu()
        menu.addItem(withTitle: "显示/隐藏悬浮窗", action: #selector(togglePanel), keyEquivalent: "")
        menu.addItem(withTitle: "设置…", action: #selector(showSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出", action: #selector(quit), keyEquivalent: "q")
        statusItem.menu = menu
    }

    private func configurePanel() {
        let panelStyle: NSWindow.StyleMask = FloatingPanelInteractionPolicy.shouldAllowUserResizing ? [.borderless, .resizable] : [.borderless]
        panel = FloatingPanel(contentRect: NSRect(x: 600, y: 500, width: 260, height: 80), styleMask: panelStyle, backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
        panel.isMovable = true; panel.isMovableByWindowBackground = true; panel.level = .normal; panel.delegate = self; panel.becomesKeyOnlyIfNeeded = false; panel.hidesOnDeactivate = false
        panel.onInitialMouseInteractionEnded = { [weak self] in self?.refresh() }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let hasCommand = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command)
            if KeyboardShortcutPolicy.isSettingsShortcut(commandPressed: hasCommand, keyCode: event.keyCode) { self?.showSettings(); return nil }
            if event.charactersIgnoringModifiers?.lowercased() == "q" { self?.quit(); return nil }
            return event
        }
        if let origin = store.windowOrigin { panel.setFrameOrigin(origin) }
    }

    func windowDidMove(_ notification: Notification) { store.windowOrigin = panel.frame.origin }
    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === panel else { return }
        panelFocused = true
        if !panel.interactionState.shouldRefreshForFocusChange,
           FloatingPanelInteractionPolicy.shouldDeferFocusRefreshWhileDispatchingFirstClick {
            return
        }
        refresh()
    }

    func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === panel else { return }
        panelFocused = false
        refresh()
    }

    func windowShouldZoom(_ window: NSWindow, toFrame newFrame: NSRect) -> Bool {
        if window === panel { return FloatingPanelInteractionPolicy.shouldAllowZoom }
        if window === settingsWindow { return SettingsWindowStylePolicy.shouldAllowZoom }
        return true
    }

    func windowShouldToggleFullScreen(_ window: NSWindow) -> Bool {
        if window === panel { return FloatingPanelInteractionPolicy.shouldAllowFullScreen }
        if window === settingsWindow { return SettingsWindowStylePolicy.shouldAllowFullScreen }
        return true
    }

    @objc private func togglePanel() { panel.isVisible ? panel.orderOut(nil) : panel.makeKeyAndOrderFront(nil) }
    @objc private func quit() { NSApp.terminate(nil) }

    private func acknowledgeNewMessages() {
        guard displaySettings.topMode == .newMessage else { return }
        badgePresentationTracker.acknowledgeCurrentValues()
        refresh()
    }

    @objc private func showSettings() {
        NSApp.setActivationPolicy(.regular)
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            refresh()
            return
        }
        let view = SettingsView(apps: apps, settings: displaySettings) { [weak self] updated, settings in self?.apps = updated; self?.displaySettings = settings; self?.store.save(updated); self?.store.saveDisplaySettings(settings); self?.refresh() }
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentRect: .zero, styleMask: SettingsWindowStylePolicy.styleMask, backing: .buffered, defer: false)
        window.contentViewController = controller

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        window.title = "【设置】未读消息 v\(appVersion) (\(buildNumber))"

        window.setContentSize(NSSize(width: 620, height: 800)); window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false; window.hidesOnDeactivate = false; window.delegate = self; settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
        refresh()
    }

    @objc private func receivedExternalSettingsRequest(_ notification: Notification) { handleExternalSettingsRequest() }

    private func handleExternalSettingsRequest() {
        guard let token = store.settingsWindowRequestToken, token != lastHandledSettingsRequest else { return }
        lastHandledSettingsRequest = token
        showSettings()
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === settingsWindow else { return }
        settingsWindow = nil
        NSApp.setActivationPolicy(.accessory)
        refresh()
    }

    private func refresh() {
        guard panel?.interactionState.shouldRefreshForFocusChange != false else { return }
        handleExternalSettingsRequest()
        let requestedApps = apps
        badgePoller.poll(dockNames: requestedApps.map(\.dockName)) { [weak self] statuses in
            self?.applyRefresh(for: requestedApps, statuses: statuses)
        }
    }

    private func applyRefresh(for requestedApps: [MonitoredApp], statuses: [BadgeReadStatus]) {
        guard panel?.interactionState.shouldRefreshForFocusChange != false else { return }
        guard requestedApps.map(\.id) == apps.map(\.id) else {
            refresh()
            return
        }
        let rows = zip(requestedApps, statuses).map { app, status -> DisplayRow in
            let raw: String?
            switch status { case .value(let value): raw = value; case .unavailable: raw = nil }
            let count = BadgeRules.unreadCount(from: raw)
            let value = (count ?? 0) > 0 ? BadgeRules.unreadValue(from: raw) : nil
            return DisplayRow(app: app, value: value, count: count)
        }
        let rawValues = rows.map(\.value)
        let visibleRows = rows.filter {
            VisibleAppPolicy.shouldShowApp(hasUnread: ($0.count ?? 0) > 0, hideAppsWithoutUnread: displaySettings.hideAppsWithoutUnread)
        }
        let badgeCounts = Dictionary(uniqueKeysWithValues: rows.compactMap { row in row.count.map { (row.app.id.uuidString, $0) } }.filter { $0.1 > 0 })
        let increasedAppIDs: [String]
        if observedTopMode != displaySettings.topMode {
            if observedTopMode != nil, displaySettings.topMode == .newMessage {
                increasedAppIDs = badgePresentationTracker.enterNewMessageMode(counts: badgeCounts)
            } else {
                badgePresentationTracker.reset(counts: badgeCounts)
                increasedAppIDs = []
            }
            observedTopMode = displaySettings.topMode
        } else {
            increasedAppIDs = badgePresentationTracker.observe(counts: badgeCounts)
        }
        let size = visibleRows.isEmpty
            ? FloatingBadgeLayout.emptyStateSize()
            : FloatingBadgeLayout.size(for: visibleRows.map { BadgeRow(name: $0.app.displayName, value: $0.value, iconSize: displaySettings.iconSize) })
        panel.contentMinSize = size
        let currentWidth = panel.contentView?.bounds.width ?? size.width
        panel.setContentSize(NSSize(width: max(currentWidth, size.width), height: size.height))
        let mutedAppIDs: Set<UUID> = Set(rows.compactMap { row in
            guard (row.count ?? 0) > 0,
                  displaySettings.topMode == .newMessage,
                  badgePresentationTracker.shouldUseMutedBadge(for: row.app.id.uuidString)
            else { return nil }
            return row.app.id
        })
        let showAcknowledgement = displaySettings.topMode == .newMessage && badgePresentationTracker.hasUnacknowledgedChange
        panel.contentView = FirstMouseHostingView(rootView: FloatingBadgeView(
            rows: visibleRows,
            settings: displaySettings,
            isFocused: panelFocused,
            mutedAppIDs: mutedAppIDs,
            showAcknowledgement: showAcknowledgement,
            onOpenApp: { [weak self] app in
                guard self?.panel.interactionState.shouldDispatchClickAction == true else { return }
                self?.open(app)
            },
            onAcknowledge: { [weak self] in
                guard self?.panel.interactionState.shouldDispatchClickAction == true else { return }
                self?.acknowledgeNewMessages()
            }
        ))
        let shouldFloat = displaySettings.shouldFloat(rawValues: rawValues, tracker: badgePresentationTracker)
        let targetSpaceBehavior = PanelSpacePolicy.behavior(for: shouldFloat)
        let spaceTransition = PanelSpacePolicy.transition(from: panelSpaceBehavior, to: targetSpaceBehavior)
        panel.level = shouldFloat ? .floating : .normal
        switch targetSpaceBehavior {
        case .crossSpaceFront:
            panel.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary, .stationary]
        case .desktopOnly:
            panel.collectionBehavior = [.managed, .fullScreenNone]
        }
        panelSpaceBehavior = targetSpaceBehavior
        if spaceTransition == .reregisterAcrossSpaces, panel.isVisible {
            panel.orderOut(nil)
        }
        if displaySettings.shouldAutomaticallyShowPanel(rawValues: rawValues, tracker: badgePresentationTracker) {
            panel.orderFrontRegardless()
            hasPresentedPanel = true
        } else if !hasPresentedPanel {
            panel.orderFront(nil)
            hasPresentedPanel = true
        }
        if SettingsWindowStylePolicy.shouldRetakeFocusAfterPanelRefresh,
           settingsWindow?.isVisible == true,
           panel.screen != nil,
           panel.screen == settingsWindow?.screen {
            settingsWindow?.makeKeyAndOrderFront(nil)
        }
        recordPresentationDiagnostic(rawValues: rawValues, observedNewMessage: !increasedAppIDs.isEmpty, shouldFloat: shouldFloat)
    }

    private func recordPresentationDiagnostic(rawValues: [String?], observedNewMessage: Bool, shouldFloat: Bool) {
        let state = "mode=\(displaySettings.topMode.rawValue); badges=\(rawValues.map { $0 ?? "-" }.joined(separator: ",")); observed=\(observedNewMessage); pending=\(badgePresentationTracker.hasUnacknowledgedChange); floating=\(shouldFloat); visible=\(panel.isVisible); level=\(panel.level); behavior=\(panel.collectionBehavior.rawValue)"
        guard state != lastPresentationDiagnostic else { return }
        lastPresentationDiagnostic = state
        presentationLogger.notice("\(state, privacy: .public)")
    }

    private func open(_ app: MonitoredApp) {
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == app.dockName }) {
            restoreMinimizedWindows(of: running)
            if AppActivationPolicy.shouldUnhideBeforeActivating { running.unhide() }
            running.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        } else if let bundlePath = app.bundlePath {
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: bundlePath), configuration: .init(), completionHandler: nil)
        }
    }

    private func restoreMinimizedWindows(of application: NSRunningApplication) {
        guard AppActivationPolicy.shouldRestoreMinimizedWindows, AXIsProcessTrusted() else { return }
        let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
        var rawWindows: CFTypeRef?
        guard AXUIElementCopyAttributeValue(applicationElement, kAXWindowsAttribute as CFString, &rawWindows) == .success,
              let windows = rawWindows as? [AXUIElement]
        else { return }
        for window in windows {
            var minimized: CFTypeRef?
            guard AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimized) == .success,
                  (minimized as? Bool) == true
            else { continue }
            AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, false as CFTypeRef)
        }
    }
}

private final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    private(set) var interactionState = FloatingPanelInteractionState()
    var onInitialMouseInteractionEnded: (() -> Void)?
    private var dragStartMouseLocation: NSPoint?
    private var dragStartWindowOrigin: NSPoint?

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            interactionState.beginInitialMouseInteraction()
            dragStartMouseLocation = NSEvent.mouseLocation
            dragStartWindowOrigin = frame.origin
            if !isKeyWindow,
               FloatingPanelInteractionPolicy.shouldPromotePanelBeforeDispatchingFirstClick {
                makeKeyAndOrderFront(nil)
            }
        } else if event.type == .leftMouseDragged,
                  let dragStartMouseLocation,
                  let dragStartWindowOrigin {
            interactionState.markAsDragged()
            setFrameOrigin(FloatingPanelDragMovement.origin(
                startOrigin: dragStartWindowOrigin,
                startMouseLocation: dragStartMouseLocation,
                currentMouseLocation: NSEvent.mouseLocation
            ))
        }
        super.sendEvent(event)
        if event.type == .leftMouseUp {
            dragStartMouseLocation = nil
            dragStartWindowOrigin = nil
            finishInitialMouseInteraction()
        }
    }

    func finishInitialMouseInteraction(refreshAfterward: Bool = true) {
        guard interactionState.isInitialMouseInteractionActive else { return }
        interactionState.endInitialMouseInteraction()
        if refreshAfterward { onInitialMouseInteractionEnded?() }
    }
}

private final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { FloatingPanelInteractionPolicy.shouldAcceptFirstMouse }
    override var mouseDownCanMoveWindow: Bool { FloatingPanelInteractionPolicy.shouldAllowBackgroundWindowDragging }
}
private struct DisplayRow: Identifiable { let app: MonitoredApp; let value: String?; let count: Int?; var id: UUID { app.id } }

private struct FloatingBadgeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAcknowledgementHovered = false
    @State private var hoveredAppIDs: Set<UUID> = []
    let rows: [DisplayRow]
    let settings: DisplaySettings
    let isFocused: Bool
    let mutedAppIDs: Set<UUID>
    let showAcknowledgement: Bool
    let onOpenApp: (MonitoredApp) -> Void
    let onAcknowledge: () -> Void
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if rows.isEmpty {
                    Text("无APP展示").foregroundStyle(bubbleForeground).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    let isAppHovered = hoveredAppIDs.contains(row.app.id)
                    HStack(spacing: 12) {
                        Button { onOpenApp(row.app) } label: {
                            HStack(spacing: 12) {
                                icon(for: row.app).resizable().frame(width: settings.iconSize, height: settings.iconSize)
                                Text(row.app.displayName).foregroundStyle(bubbleForeground).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 3)
                            .background(bubbleForeground.opacity(PointerCursorPolicy.applicationRowBackgroundOpacity(isHovered: isAppHovered)))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ApplicationRowButtonStyle(isHovered: isAppHovered))
                        .onHover { isHovering in
                            if isHovering {
                                hoveredAppIDs.insert(row.app.id)
                            } else {
                                hoveredAppIDs.remove(row.app.id)
                            }
                            guard PointerCursorPolicy.shouldUsePointingHandForAppActivation else { return }
                            isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                        }
                        Text(row.value ?? "—").font(.system(size: row.value == nil ? 15 : 16, weight: .bold, design: .rounded)).foregroundStyle(row.value == nil ? bubbleForeground.opacity(0.65) : Color.white).padding(.horizontal, row.value == nil ? 0 : 9).padding(.vertical, row.value == nil ? 0 : 3).background(row.value == nil ? Color.clear : (mutedAppIDs.contains(row.app.id) ? Color.gray : Color.red)).clipShape(Capsule())
                    }.padding(.horizontal, 12).padding(.vertical, 8)
                }
            }.padding(.bottom, AcknowledgementButtonLayout.contentBottomPadding(isVisible: showAcknowledgement))
            if showAcknowledgement {
                Button(action: onAcknowledge) {
                    Text("❌ \(settings.acknowledgementButtonText)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(acknowledgementForeground)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: settings.backgroundColorHex).opacity(AcknowledgementButtonLayout.backgroundOpacity(isBubbleFocused: isFocused, configuredOpacity: settings.backgroundOpacity)))
                        .clipShape(RoundedRectangle(cornerRadius: AcknowledgementButtonLayout.cornerRadius, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: AcknowledgementButtonLayout.cornerRadius, style: .continuous).stroke(acknowledgementForeground.opacity(AcknowledgementButtonLayout.borderOpacity(isHovered: isAcknowledgementHovered)), lineWidth: 1))
                        .shadow(color: acknowledgementForeground.opacity(0.22), radius: AcknowledgementButtonLayout.shadowRadius(isHovered: isAcknowledgementHovered), y: isAcknowledgementHovered ? 3 : 2)
                }
                .buttonStyle(AcknowledgementButtonStyle(isHovered: isAcknowledgementHovered))
                .onHover { isHovered in
                    isAcknowledgementHovered = isHovered
                    isHovered ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                }
                .padding(.bottom, 7)
                .padding(.trailing, 10)
            }
        }
        .padding(.vertical, 12)
        .background(Color(hex: settings.backgroundColorHex).opacity(settings.backgroundOpacity))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var bubbleForeground: Color {
        BubbleForegroundPolicy.style(for: settings.backgroundColorHex) == .dark ? .black : .white
    }

    private var acknowledgementForeground: Color {
        bubbleForeground
    }

    private func icon(for app: MonitoredApp) -> Image {
        if let path = app.iconOverridePath, let image = NSImage(contentsOfFile: path) { return Image(nsImage: image) }
        if let path = app.bundlePath { return Image(nsImage: NSWorkspace.shared.icon(forFile: path)) }
        if let url = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == app.dockName })?.bundleURL {
            return Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
        }
        return Image(systemName: "app")
    }
}

private struct AcknowledgementButtonStyle: ButtonStyle {
    let isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .offset(y: AcknowledgementButtonLayout.verticalOffset(isHovered: isHovered))
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private struct ApplicationRowButtonStyle: ButtonStyle {
    let isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .offset(y: PointerCursorPolicy.applicationRowVerticalOffset(isHovered: isHovered))
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private struct SettingsView: View {
    @State var apps: [MonitoredApp]
    @State var settings: DisplaySettings
    @State private var selectedApplication: ApplicationPickerSelection?
    @State private var accessibilityGranted = AXIsProcessTrusted()
    let onSave: ([MonitoredApp], DisplaySettings) -> Void
    private var runningApplicationOptions: [RunningApplicationOption] {
        let candidates = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { application -> RunningApplicationOption? in
                guard let displayName = application.localizedName else { return nil }
                return RunningApplicationOption(
                    displayName: displayName,
                    bundleIdentifier: application.bundleIdentifier,
                    bundlePath: application.bundleURL?.path
                )
            }
        let withoutCurrentApp = candidates.filter { $0.bundleIdentifier != Bundle.main.bundleIdentifier }
        let uniqueOptions = Dictionary(grouping: withoutCurrentApp, by: { option in
            option.bundleIdentifier ?? option.bundlePath ?? option.displayName
        }).compactMap { $0.value.first }

        return uniqueOptions.sorted {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionCard(area: .permission, title: "权限") {
                HStack {
                    if accessibilityGranted { Label("已获得辅助功能权限", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
                    else { Button("请求授权：如果失败，则手动删除原有赋权再添加") { requestPermission() }.frame(minWidth: 120) }
                    Spacer()
                }
            }
            SettingsSectionCard(area: .appearance, title: "显示设置") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack { Text("图标大小"); TextField("", value: $settings.iconSize, format: .number).frame(width: 54); Button("−") { settings.iconSize = DisplaySettings.decreasedIconSize(from: settings.iconSize) }; Button("+") { settings.iconSize = DisplaySettings.increasedIconSize(from: settings.iconSize) }; }
                    HStack{
                        ColorPicker("背景色", selection: Binding(get: { Color(hex: settings.backgroundColorHex) }, set: { settings.backgroundColorHex = $0.hexString })); Text("透明度"); Slider(value: $settings.backgroundOpacity, in: 0.2...1).frame(width: 110)}
                    Picker("置顶方式", selection: $settings.topMode) {
                        Text("始终置顶").tag(TopMode.always)
                        Text("有消息置顶").tag(TopMode.unreadMessage)
                        Text("新消息置顶").tag(TopMode.newMessage)
                    }.pickerStyle(.menu)
                    Toggle("隐藏无消息应用", isOn: $settings.hideAppsWithoutUnread).toggleStyle(.checkbox)
                    HStack { Text("按钮文字"); TextField("晓得了", text: $settings.acknowledgementButtonText).textFieldStyle(.roundedBorder).frame(width: 180); Spacer() }
                }
            }
            SettingsSectionCard(area: .applicationList, title: "应用设置") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Picker("选择应用", selection: $selectedApplication) {
                            Text("选择应用").tag(nil as ApplicationPickerSelection?)
                            ForEach(runningApplicationOptions, id: \.self) { option in
                                Text(option.displayName).tag(Optional(ApplicationPickerSelection.running(option)))
                            }
                            Divider()
                            Text("选择本地 App…").tag(Optional(ApplicationPickerSelection.localApp))
                        }
                        .frame(width: 220)
                        .onChange(of: selectedApplication) { selection in
                            guard let selection else { return }
                            switch selection {
                            case .running(let option):
                                add(option.displayName, bundlePath: option.bundlePath)
                            case .localApp:
                                chooseApplication()
                            }
                            selectedApplication = nil
                        }
                        Spacer()
                    }

                }
                List { ForEach($apps) { $app in HStack { Image(systemName: "line.3.horizontal").foregroundStyle(.secondary); appIcon(for: app).resizable().frame(width: 28, height: 28); Text(app.dockName).foregroundStyle(.secondary).frame(width: 90, alignment: .leading); TextField("自定义显示名称", text: $app.displayName).textFieldStyle(.roundedBorder).frame(minWidth: 150); Button("图片") { chooseIcon(for: app.id) }; if app.iconOverridePath != nil { Button("删除图片") { app.iconOverridePath = nil } }; Button(role: .destructive) { apps.removeAll { $0.id == app.id } } label: { Image(systemName: "trash") } } }.onDelete { apps.remove(atOffsets: $0) }.onMove { apps.move(fromOffsets: $0, toOffset: $1); for index in apps.indices { apps[index].sortOrder = index } } }.frame(height: 190)
            }
        }
        .padding()
        .onChange(of: apps) { _ in onSave(apps, settings) }
        .onChange(of: settings) { _ in onSave(apps, settings) }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            accessibilityGranted = AXIsProcessTrusted()
        }
    }
    private func add(_ name: String, bundlePath: String? = nil) { guard !name.isEmpty, !apps.contains(where: { $0.dockName == name }) else { return }; let resolvedBundlePath = bundlePath ?? NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name })?.bundleURL?.path; apps.append(MonitoredApp(dockName: name, displayName: name, bundlePath: resolvedBundlePath, sortOrder: apps.count)) }
    private func chooseIcon(for id: UUID) { let panel = NSOpenPanel(); panel.allowedContentTypes = [.image]; panel.allowsMultipleSelection = false; if panel.runModal() == .OK, let path = panel.url?.path, let index = apps.firstIndex(where: { $0.id == id }) { apps[index].iconOverridePath = path } }
    private func chooseApplication() { let panel = NSOpenPanel(); panel.allowedContentTypes = [.applicationBundle]; panel.allowsMultipleSelection = false; if panel.runModal() == .OK, let url = panel.url, let bundle = Bundle(url: url), let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String { add(name, bundlePath: url.path) } }
    private func requestPermission() {
        for action in AccessibilityPermissionPolicy.actions(isTrusted: AXIsProcessTrusted()) {
            switch action {
            case .prompt:
                AXIsProcessTrustedWithOptions([
                    kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
                ] as CFDictionary)
            case .openSystemSettings:
                NSWorkspace.shared.open(AccessibilityPermissionPolicy.systemSettingsURL)
            case .refreshStatus:
                accessibilityGranted = AXIsProcessTrusted()
            }
        }
    }
    private func appIcon(for app: MonitoredApp) -> Image { if let path = app.iconOverridePath, let image = NSImage(contentsOfFile: path) { return Image(nsImage: image) }; if let path = app.bundlePath { return Image(nsImage: NSWorkspace.shared.icon(forFile: path)) }; if let url = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == app.dockName })?.bundleURL { return Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)) }; return Image(systemName: "app") }
}

private struct RunningApplicationOption: Hashable {
    let displayName: String
    let bundleIdentifier: String?
    let bundlePath: String?
}

private enum ApplicationPickerSelection: Hashable {
    case running(RunningApplicationOption)
    case localApp
}

private struct SettingsSectionCard<Content: View>: View {
    let area: SettingsArea
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            if SettingsSectionPresentationPolicy.presentation(for: area) == .cardWithDivider {
                Divider()
            }
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1))
    }
}

private extension Color {
    init(hex: String) { let value = UInt64(hex, radix: 16) ?? 0; self.init(.sRGB, red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1) }
    var hexString: String { let color = NSColor(self).usingColorSpace(.sRGB) ?? .black; return String(format: "%02X%02X%02X", Int(color.redComponent * 255), Int(color.greenComponent * 255), Int(color.blueComponent * 255)) }
}

let application = NSApplication.shared
let appDelegate = BadgeAppDelegate()
application.delegate = appDelegate
let existingProcessIDs = Bundle.main.bundleIdentifier.map {
    NSRunningApplication.runningApplications(withBundleIdentifier: $0).map(\.processIdentifier)
} ?? []
if InstanceLaunchPolicy.action(existingProcessIDs: existingProcessIDs, currentProcessID: ProcessInfo.processInfo.processIdentifier) == .forwardSettingsRequest {
    AppConfigurationStore().requestSettingsWindow()
    DistributedNotificationCenter.default().postNotificationName(showSettingsNotification, object: nil, userInfo: nil, deliverImmediately: true)
    exit(0)
}
application.setActivationPolicy(.accessory)
application.run()
