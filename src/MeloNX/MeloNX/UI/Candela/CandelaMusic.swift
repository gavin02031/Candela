// SPDX-License-Identifier: AGPL-3.0-or-later
// Candela Music: the user's local/synced Music library, presented as a pastel
// handheld-style music hub. No developer token, uploaded tracks or cloud account.
import SwiftUI
import MediaPlayer
import Combine

@MainActor
final class CandelaMusic: ObservableObject {
    static let shared = CandelaMusic()

    @Published var status: MPMediaLibraryAuthorizationStatus = MPMediaLibrary.authorizationStatus()
    @Published var title = ""
    @Published var artist = ""
    @Published var artwork: UIImage?
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var elapsed: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var hasItem = false
    @Published var shuffleEnabled = false
    @Published var repeatEnabled = false
    @Published var playlists: [MPMediaPlaylist] = []
    @Published var albums: [MPMediaItemCollection] = []

    private let player = MPMusicPlayerController.applicationMusicPlayer
    private var timer: Timer?
    private var started = false
    private var observers: [NSObjectProtocol] = []

    private init() {
        if status == .authorized { start() }
    }

    func requestAccess() {
        MPMediaLibrary.requestAuthorization { [weak self] new in
            Task { @MainActor in
                self?.status = new
                if new == .authorized { self?.start() }
            }
        }
    }

    private func start() {
        guard !started else {
            loadLibrary()
            refresh()
            return
        }
        started = true
        loadLibrary()
        player.beginGeneratingPlaybackNotifications()
        observers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // Keep Candela's established behavior: music pauses on background.
                if self.player.playbackState == .playing { self.player.pause() }
                self.refresh()
            }
        })
        for name in [
            Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
            Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange
        ] {
            observers.append(NotificationCenter.default.addObserver(
                forName: name, object: player, queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            })
        }
        observers.append(NotificationCenter.default.addObserver(
            forName: .MPMediaLibraryDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.loadLibrary() }
        })
        MPMediaLibrary.default().beginGeneratingLibraryChangeNotifications()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        refresh()
    }

    func loadLibrary() {
        guard status == .authorized else { return }
        playlists = (MPMediaQuery.playlists().collections as? [MPMediaPlaylist]) ?? []
        albums = MPMediaQuery.albums().collections ?? []
    }

    private func refresh() {
        isPlaying = player.playbackState == .playing
        shuffleEnabled = player.shuffleMode == .songs
        repeatEnabled = player.repeatMode == .all || player.repeatMode == .one
        if let item = player.nowPlayingItem {
            hasItem = true
            title = item.title ?? "Unknown track"
            artist = item.artist ?? "Unknown artist"
            artwork = item.artwork?.image(at: CGSize(width: 520, height: 520))
            tick()
        } else {
            hasItem = false
            title = ""
            artist = ""
            artwork = nil
            elapsed = 0
            duration = 0
            progress = 0
        }
    }

    private func tick() {
        guard let item = player.nowPlayingItem else {
            elapsed = 0
            duration = 0
            progress = 0
            return
        }
        duration = max(0, item.playbackDuration)
        elapsed = max(0, player.currentPlaybackTime)
        progress = duration > 0 ? min(1, max(0, elapsed / duration)) : 0
    }

    func play(_ collection: MPMediaItemCollection) {
        guard !collection.items.isEmpty else { return }
        player.setQueue(with: collection)
        player.shuffleMode = .off
        player.play()
        refresh()
    }

    func shuffle(_ collection: MPMediaItemCollection) {
        guard !collection.items.isEmpty else { return }
        player.setQueue(with: collection)
        player.shuffleMode = .songs
        player.play()
        refresh()
    }

    func playTrack(_ item: MPMediaItem) {
        player.setQueue(with: MPMediaItemCollection(items: [item]))
        player.shuffleMode = .off
        player.play()
        refresh()
    }

    func toggle() {
        guard hasItem else { return }
        isPlaying ? player.pause() : player.play()
        refresh()
    }

    func next() { player.skipToNextItem(); refresh() }
    func previous() { player.skipToPreviousItem(); refresh() }

    func toggleShuffle() {
        player.shuffleMode = shuffleEnabled ? .off : .songs
        refresh()
    }

    func toggleRepeat() {
        player.repeatMode = repeatEnabled ? .none : .all
        refresh()
    }

    func seek(to fraction: Double) {
        guard let item = player.nowPlayingItem, item.playbackDuration > 0 else { return }
        player.currentPlaybackTime = min(1, max(0, fraction)) * item.playbackDuration
        tick()
    }
}

// MARK: - Shared visual primitives

private struct CandelaMusicArtwork: View {
    let image: UIImage?
    var size: CGFloat
    var cornerRadius: CGFloat = 17
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        Color(candelaHex: 0xE9D8F8),
                        Color(candelaHex: 0xC5E9E0),
                        Color(candelaHex: 0xF8D8E7)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.38, weight: .medium))
                    .foregroundColor(Color(candelaHex: 0x805D94).opacity(0.85))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(scheme == .dark ? 0.25 : 0.8), lineWidth: 1.2)
        }
        .accessibilityHidden(true)
    }
}

private struct CandelaMusicLabel: View {
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) private var scheme
    private var p: CandelaPalette { CandelaPalette(dark: scheme == .dark) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(p.ink)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(p.inkSoft)
        }
    }
}

private extension TimeInterval {
    var candelaMusicClock: String {
        let value = max(0, Int(isFinite ? self : 0))
        return String(format: "%d:%02d", value / 60, value % 60)
    }
}

// MARK: - Compact player used throughout the launcher

struct CandelaMiniPlayer: View {
    @ObservedObject var music: CandelaMusic
    var open: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    private var palette: CandelaPalette { CandelaPalette(dark: colorScheme == .dark) }

    var body: some View {
        HStack(spacing: 11) {
            Button(action: open) {
                HStack(spacing: 10) {
                    CandelaMusicArtwork(image: music.artwork, size: 45, cornerRadius: 13)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(music.title)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(palette.ink)
                            .lineLimit(1)
                        Text(music.artist.isEmpty ? "Music" : music.artist)
                            .font(.caption)
                            .foregroundColor(palette.inkSoft)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 2)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open music player, \(music.title)")
            Button { music.toggle() } label: {
                Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(palette.ink)
                    .frame(width: 39, height: 39)
                    .background(palette.roseSoft.opacity(0.65), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(music.isPlaying ? "Pause music" : "Play music")
            Button { music.next() } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(palette.rose)
                    .frame(width: 34, height: 39)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next track")
        }
        .padding(9)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(palette.cardStroke.opacity(0.9), lineWidth: 1)
        }
        .shadow(color: palette.rose.opacity(0.14), radius: 11, y: 4)
        .padding(.horizontal, 16)
    }
}

// MARK: - Music hub: browse first, full player on demand

private enum CandelaMusicShelf: String, CaseIterable, Identifiable {
    case playlists = "Playlists"
    case albums = "Albums"
    var id: String { rawValue }
}

private struct CandelaMusicSelection: Identifiable {
    let id = UUID()
    let collection: MPMediaItemCollection
    let title: String
}

struct CandelaMusicView: View {
    @ObservedObject var music: CandelaMusic = .shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var search = ""
    @State private var shelf: CandelaMusicShelf = .playlists
    @State private var showPlayer = false
    @State private var selectedCollection: CandelaMusicSelection?

    private var palette: CandelaPalette { CandelaPalette(dark: scheme == .dark) }

    private var filteredPlaylists: [MPMediaPlaylist] {
        music.playlists.filter {
            search.isEmpty || ($0.name ?? "Playlist").localizedCaseInsensitiveContains(search)
        }
    }

    private var filteredAlbums: [MPMediaItemCollection] {
        music.albums.filter {
            guard !search.isEmpty else { return true }
            let item = $0.representativeItem
            return (item?.albumTitle ?? "").localizedCaseInsensitiveContains(search)
                || (item?.albumArtist ?? item?.artist ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    heading
                    if music.status == .authorized {
                        listeningCard
                        browseSection
                    } else {
                        permission
                    }
                }
                .padding(.horizontal, 19)
                .padding(.top, 14)
                .padding(.bottom, 35)
            }
            .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Music")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(palette.ink)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(palette.ink)
                            .frame(width: 34, height: 34)
                            .background(palette.card.opacity(0.85), in: Circle())
                    }
                    .accessibilityLabel("Close music")
                }
                if music.status == .authorized {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { music.loadLibrary() } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(palette.rose)
                        }
                        .accessibilityLabel("Refresh music library")
                    }
                }
            }
            .sheet(isPresented: $showPlayer) {
                CandelaFullMusicPlayer(music: music)
            }
            .sheet(item: $selectedCollection) { selection in
                CandelaMusicCollectionView(music: music, collection: selection.collection,
                                          collectionTitle: selection.title)
            }
            .onAppear {
                if music.status == .authorized { music.loadLibrary() }
            }
        }
        .tint(palette.rose)
    }

    private var heading: some View {
        HStack(alignment: .center, spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(
                        colors: [palette.roseSoft.opacity(0.93), palette.skySoft.opacity(0.65)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 59, height: 59)
                Image(systemName: "music.note.list")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(palette.rose)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("YOUR SOUNDTRACK")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.8)
                    .foregroundColor(palette.rose)
                Text("Listen your way.")
                    .font(.system(size: 23, weight: .heavy, design: .rounded))
                    .foregroundColor(palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("The music you love, alongside your games.")
                    .font(.system(size: 12))
                    .foregroundColor(palette.inkSoft)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 1)
    }

    private var permission: some View {
        VStack(spacing: 17) {
            Image(systemName: "music.quarternote.3")
                .font(.system(size: 46))
                .foregroundColor(palette.rose)
                .frame(width: 96, height: 96)
                .background(palette.roseSoft.opacity(0.42), in: RoundedRectangle(cornerRadius: 27))
            Text("Bring your music into Candela")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundColor(palette.ink)
                .multilineTextAlignment(.center)
            Text("Browse your Music playlists and albums right here. Nothing is uploaded to Candela.")
                .font(.subheadline)
                .foregroundColor(palette.inkSoft)
                .multilineTextAlignment(.center)
            Button(music.status == .denied || music.status == .restricted ? "Open Music permissions" : "Allow Music access") {
                if music.status == .denied || music.status == .restricted {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } else {
                    music.requestAccess()
                }
            }
            .buttonStyle(CandelaPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(27)
        .candelaSurface(radius: 28)
    }

    private var listeningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(music.hasItem ? "NOW PLAYING" : "READY WHEN YOU ARE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.8)
                    .foregroundColor(palette.rose)
                Spacer()
                if music.hasItem {
                    Text("OPEN PLAYER")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundColor(palette.inkSoft)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(palette.rose)
                } else {
                    Image(systemName: "sparkles")
                        .foregroundColor(palette.rose)
                }
            }

            HStack(spacing: 13) {
                CandelaMusicArtwork(image: music.artwork, size: 84, cornerRadius: 18)
                    .shadow(color: palette.rose.opacity(0.14), radius: 8, y: 3)

                VStack(alignment: .leading, spacing: 6) {
                    Text(music.hasItem ? music.title : "Your next favorite song")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(palette.ink)
                        .lineLimit(2)
                    Text(music.hasItem ? music.artist : "Choose a playlist or album below")
                        .font(.system(size: 12))
                        .foregroundColor(palette.inkSoft)
                        .lineLimit(2)
                    if music.hasItem {
                        Button { showPlayer = true } label: {
                            HStack(spacing: 6) {
                                Text("Full player")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(palette.rose)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer(minLength: 0)
                if music.hasItem {
                    Button { music.toggle() } label: {
                        Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(palette.primaryButtonInk)
                            .frame(width: 43, height: 43)
                            .background(palette.accentGradient, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(music.isPlaying ? "Pause" : "Play")
                }
            }

            if music.hasItem {
                GeometryReader { proxy in
                    Capsule()
                        .fill(palette.rose.opacity(0.15))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(palette.rose)
                                .frame(width: max(0, proxy.size.width * music.progress))
                        }
                }
                .frame(height: 4)
                .accessibilityLabel("Playback progress")
                .accessibilityValue("\(Int(music.progress * 100)) percent")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        palette.card.opacity(0.98),
                        palette.roseSoft.opacity(0.34),
                        palette.skySoft.opacity(0.32)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .strokeBorder(palette.cardStroke.opacity(0.9), lineWidth: 1)
        }
        .shadow(color: palette.rose.opacity(0.09), radius: 13, y: 6)
    }

    private var browseSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                CandelaMusicLabel(title: "Your collection", subtitle: "Playlists, albums and all your favorites")
                Spacer(minLength: 4)
                Text("\(music.playlists.count + music.albums.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(palette.rose)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(palette.roseSoft.opacity(0.46), in: Capsule())
                    .accessibilityLabel("\(music.playlists.count) playlists and \(music.albums.count) albums")
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(palette.rose)
                TextField("Search \(shelf.rawValue.lowercased())", text: $search)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(palette.ink)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(palette.inkSoft)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 15)
            .frame(height: 48)
            .background(palette.card.opacity(0.94), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(palette.cardStroke, lineWidth: 1))

            HStack(spacing: 8) {
                ForEach(CandelaMusicShelf.allCases) { value in
                    Button {
                        withAnimation(.easeInOut(duration: 0.17)) { shelf = value }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: value == .playlists ? "music.note.list" : "square.stack.fill")
                            Text(value.rawValue)
                            Text("\(value == .playlists ? music.playlists.count : music.albums.count)")
                                .font(.system(size: 10, weight: .semibold))
                                .opacity(0.67)
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(shelf == value ? palette.ink : palette.inkSoft)
                        .padding(.horizontal, 15)
                        .frame(height: 41)
                        .background(shelf == value ? palette.roseSoft.opacity(0.66) : palette.card.opacity(0.68),
                                    in: Capsule())
                        .overlay(Capsule().strokeBorder(shelf == value ? palette.rose.opacity(0.50) : palette.cardStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }

            if shelf == .playlists { playlistSection }
            else { albumSection }
        }
    }

    private var playlistSection: some View {
        LazyVStack(spacing: 11) {
            ForEach(filteredPlaylists, id: \.persistentID) { list in
                playlistRow(list)
            }
            if filteredPlaylists.isEmpty {
                emptyCollection(search.isEmpty ? "No playlists yet" : "No matching playlists",
                                detail: "Your playlists from Music appear here.",
                                icon: "music.note.list")
            }
        }
    }

    private func playlistRow(_ list: MPMediaPlaylist) -> some View {
        let name = list.name ?? "Playlist"
        let count = list.count
        return HStack(spacing: 12) {
            Button {
                selectedCollection = CandelaMusicSelection(collection: list, title: name)
            } label: {
                HStack(spacing: 12) {
                    CandelaMusicArtwork(
                        image: list.representativeItem?.artwork?.image(at: CGSize(width: 110, height: 110)),
                        size: 56, cornerRadius: 15
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(palette.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text("\(count) \(count == 1 ? "song" : "songs")")
                            .font(.system(size: 12))
                            .foregroundColor(palette.inkSoft)
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Browse playlist \(name)")
            Button { music.play(list) } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(palette.primaryButtonInk)
                    .frame(width: 39, height: 39)
                    .background(palette.roseSoft.opacity(0.78), in: Circle())
            }
            .disabled(list.items.isEmpty)
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(name)")
        }
        .padding(11)
        .background(palette.card.opacity(0.84), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(palette.cardStroke, lineWidth: 1))
        .contextMenu {
            Button { music.play(list) } label: { Label("Play", systemImage: "play.fill") }
            Button { music.shuffle(list) } label: { Label("Shuffle", systemImage: "shuffle") }
        }
    }

    private var albumSection: some View {
        VStack(spacing: 11) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 13), GridItem(.flexible(), spacing: 13)],
                      spacing: 13) {
                ForEach(filteredAlbums, id: \.persistentID) { album in
                    let name = album.representativeItem?.albumTitle ?? "Album"
                    Button {
                        selectedCollection = CandelaMusicSelection(collection: album, title: name)
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            GeometryReader { proxy in
                                CandelaMusicArtwork(
                                    image: album.representativeItem?.artwork?.image(at: CGSize(width: 320, height: 320)),
                                    size: max(1, proxy.size.width), cornerRadius: 17
                                )
                            }
                            .aspectRatio(1, contentMode: .fit)
                            Text(name)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(palette.ink)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(album.representativeItem?.albumArtist ?? album.representativeItem?.artist ?? "Artist")
                                .font(.system(size: 11))
                                .foregroundColor(palette.inkSoft)
                                .lineLimit(1)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.card.opacity(0.85), in: RoundedRectangle(cornerRadius: 21))
                        .overlay(RoundedRectangle(cornerRadius: 21).strokeBorder(palette.cardStroke, lineWidth: 1))
                    }
                    .buttonStyle(CandelaPressStyle())
                    .contextMenu {
                        Button { music.play(album) } label: { Label("Play album", systemImage: "play.fill") }
                        Button { music.shuffle(album) } label: { Label("Shuffle album", systemImage: "shuffle") }
                    }
                }
            }
            if filteredAlbums.isEmpty {
                emptyCollection(search.isEmpty ? "No albums yet" : "No matching albums",
                                detail: "Your saved music albums appear here.",
                                icon: "square.stack")
            }
        }
    }

    private func emptyCollection(_ title: String, detail: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 27))
                .foregroundColor(palette.rose)
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(palette.ink)
            Text(detail)
                .font(.subheadline)
                .foregroundColor(palette.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 139)
        .padding()
        .candelaSurface(radius: 20)
    }
}

// MARK: - Collection detail: browse, play, shuffle, individual song selection

private struct CandelaMusicCollectionView: View {
    @ObservedObject var music: CandelaMusic
    let collection: MPMediaItemCollection
    let collectionTitle: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private var p: CandelaPalette { CandelaPalette(dark: scheme == .dark) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 15) {
                        CandelaMusicArtwork(
                            image: collection.representativeItem?.artwork?.image(at: CGSize(width: 330, height: 330)),
                            size: 113, cornerRadius: 22
                        )
                        VStack(alignment: .leading, spacing: 7) {
                            Text(collectionTitle)
                                .font(.system(size: 23, weight: .heavy, design: .rounded))
                                .foregroundColor(p.ink)
                                .lineLimit(3)
                                .minimumScaleFactor(0.7)
                            Text("\(collection.count) \(collection.count == 1 ? "song" : "songs")")
                                .font(.subheadline)
                                .foregroundColor(p.inkSoft)
                            Text("FROM YOUR MUSIC LIBRARY")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .tracking(1.0)
                                .foregroundColor(p.rose)
                        }
                    }
                    HStack(spacing: 11) {
                        Button { music.play(collection) } label: {
                            Label("Play all", systemImage: "play.fill")
                                .frame(maxWidth: .infinity, minHeight: 46)
                        }
                        .buttonStyle(CandelaPrimaryButtonStyle())
                        .disabled(collection.items.isEmpty)
                        Button { music.shuffle(collection) } label: {
                            Label("Shuffle", systemImage: "shuffle")
                                .frame(maxWidth: .infinity, minHeight: 46)
                        }
                        .buttonStyle(CandelaSecondaryButtonStyle())
                        .disabled(collection.items.isEmpty)
                    }

                    Text("TRACKS")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.8)
                        .foregroundColor(p.rose)
                        .padding(.top, 6)
                    LazyVStack(spacing: 8) {
                        ForEach(Array(collection.items.enumerated()), id: \.element.persistentID) { index, item in
                            Button { music.playTrack(item) } label: {
                                HStack(spacing: 11) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(p.inkSoft)
                                        .frame(width: 22)
                                    CandelaMusicArtwork(
                                        image: item.artwork?.image(at: CGSize(width: 90, height: 90)),
                                        size: 44, cornerRadius: 11
                                    )
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.title ?? "Unknown track")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(p.ink)
                                            .lineLimit(1)
                                        Text(item.artist ?? "Unknown artist")
                                            .font(.caption)
                                            .foregroundColor(p.inkSoft)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 5)
                                    Text(item.playbackDuration.candelaMusicClock)
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundColor(p.inkSoft)
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(p.rose)
                                }
                                .padding(9)
                                .candelaSurface(radius: 16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 25)
            }
            .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .tint(p.rose)
    }
}

// MARK: - Full immersive player, only shown when requested

private struct CandelaFullMusicPlayer: View {
    @ObservedObject var music: CandelaMusic
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var seek = 0.0
    @State private var scrubbing = false

    private var p: CandelaPalette { CandelaPalette(dark: scheme == .dark) }

    var body: some View {
        GeometryReader { geometry in
            let artSide = min(geometry.size.width - 82, 310.0)
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button { dismiss() } label: {
                            Label("Library", systemImage: "chevron.down")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(p.ink)
                                .padding(.horizontal, 13)
                                .frame(height: 40)
                                .background(p.card.opacity(0.81), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text("NOW PLAYING")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1.8)
                            .foregroundColor(p.rose)
                        Spacer()
                        Image(systemName: "waveform")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(p.rose)
                            .frame(width: 40, height: 40)
                            .background(p.card.opacity(0.77), in: Circle())
                    }

                    Spacer(minLength: 4)

                    CandelaMusicArtwork(
                        image: music.artwork, size: max(160, artSide), cornerRadius: 32
                    )
                    .shadow(color: p.rose.opacity(0.22), radius: 23, y: 10)
                    .padding(.vertical, 8)

                    VStack(spacing: 7) {
                        Text(music.title.isEmpty ? "Nothing playing" : music.title)
                            .font(.system(size: 25, weight: .heavy, design: .rounded))
                            .foregroundColor(p.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Text(music.artist.isEmpty ? "Choose something from your library" : music.artist)
                            .font(.system(size: 15))
                            .foregroundColor(p.inkSoft)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Slider(value: Binding(
                            get: { scrubbing ? seek : music.progress },
                            set: { seek = $0 }
                        ), in: 0...1) { editing in
                            scrubbing = editing
                            if !editing { music.seek(to: seek) }
                        }
                        .tint(p.rose)
                        .disabled(!music.hasItem || music.duration <= 0)
                        .accessibilityLabel("Scrub track position")
                        HStack {
                            Text((scrubbing ? seek * music.duration : music.elapsed).candelaMusicClock)
                            Spacer()
                            Text(music.duration.candelaMusicClock)
                        }
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(p.inkSoft)
                    }

                    HStack(spacing: 23) {
                        Button { music.toggleShuffle() } label: {
                            Image(systemName: "shuffle")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(music.shuffleEnabled ? p.rose : p.inkSoft)
                                .frame(width: 38, height: 45)
                        }
                        .accessibilityLabel(music.shuffleEnabled ? "Disable shuffle" : "Enable shuffle")

                        Button { music.previous() } label: {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 23))
                                .foregroundColor(p.ink)
                                .frame(width: 44, height: 54)
                        }
                        .accessibilityLabel("Previous track")

                        Button { music.toggle() } label: {
                            Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 27, weight: .bold))
                                .foregroundColor(p.primaryButtonInk)
                                .frame(width: 77, height: 77)
                                .background(p.accentGradient, in: Circle())
                                .overlay(Circle().strokeBorder(.white.opacity(0.79), lineWidth: 2))
                                .shadow(color: p.rose.opacity(0.26), radius: 16, y: 7)
                        }
                        .accessibilityLabel(music.isPlaying ? "Pause" : "Play")

                        Button { music.next() } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 23))
                                .foregroundColor(p.ink)
                                .frame(width: 44, height: 54)
                        }
                        .accessibilityLabel("Next track")

                        Button { music.toggleRepeat() } label: {
                            Image(systemName: "repeat")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(music.repeatEnabled ? p.rose : p.inkSoft)
                                .frame(width: 38, height: 45)
                        }
                        .accessibilityLabel(music.repeatEnabled ? "Disable repeat" : "Enable repeat")
                    }
                    .disabled(!music.hasItem)
                    .buttonStyle(.plain)

                    Text("YOUR MUSIC, YOUR MOMENT")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.7)
                        .foregroundColor(p.inkSoft)
                        .padding(.top, 9)
                    Spacer(minLength: 7)
                }
                .padding(.horizontal, 25)
                .padding(.top, 17)
                .padding(.bottom, 25)
                .frame(minHeight: geometry.size.height)
            }
            .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
        }
        .tint(p.rose)
    }
}
