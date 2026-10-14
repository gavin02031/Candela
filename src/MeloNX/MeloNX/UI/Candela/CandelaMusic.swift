// SPDX-License-Identifier: AGPL-3.0-or-later
// Music player backed by the user's own media library (downloaded and synced tracks, plus streamed ones when
// the user has a subscription). It uses the system music player, so it needs no developer token.
import SwiftUI
import MediaPlayer

@MainActor
final class CandelaMusic: ObservableObject {
    static let shared = CandelaMusic()

    @Published var status: MPMediaLibraryAuthorizationStatus = MPMediaLibrary.authorizationStatus()
    @Published var title = ""
    @Published var artist = ""
    @Published var artwork: UIImage?
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var hasItem = false
    @Published var playlists: [MPMediaPlaylist] = []
    @Published var albums: [MPMediaItemCollection] = []

    private let player = MPMusicPlayerController.applicationMusicPlayer
    private var timer: Timer?

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
        loadLibrary()
        player.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        NotificationCenter.default.addObserver(forName: .MPMusicPlayerControllerPlaybackStateDidChange, object: player, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        refresh()
    }

    func loadLibrary() {
        playlists = (MPMediaQuery.playlists().collections as? [MPMediaPlaylist]) ?? []
        albums = MPMediaQuery.albums().collections ?? []
    }

    private func refresh() {
        isPlaying = player.playbackState == .playing
        if let item = player.nowPlayingItem {
            hasItem = true
            title = item.title ?? "Unknown"
            artist = item.artist ?? ""
            artwork = item.artwork?.image(at: CGSize(width: 300, height: 300))
        } else {
            hasItem = false
        }
    }

    private func tick() {
        guard let item = player.nowPlayingItem, item.playbackDuration > 0 else { progress = 0; return }
        progress = min(1, max(0, player.currentPlaybackTime / item.playbackDuration))
    }

    func play(_ collection: MPMediaItemCollection) {
        player.setQueue(with: collection)
        player.shuffleMode = .off
        player.play()
        refresh()
    }

    func shuffle(_ collection: MPMediaItemCollection) {
        player.setQueue(with: collection)
        player.shuffleMode = .songs
        player.play()
        refresh()
    }

    func toggle() { isPlaying ? player.pause() : player.play(); refresh() }
    func next() { player.skipToNextItem() }
    func previous() { player.skipToPreviousItem() }
    func seek(to fraction: Double) {
        guard let item = player.nowPlayingItem else { return }
        player.currentPlaybackTime = fraction * item.playbackDuration
    }
}

// MARK: - Mini player pill

struct CandelaMiniPlayer: View {
    @ObservedObject var music: CandelaMusic
    var open: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    private var palette: CandelaPalette { CandelaPalette(dark: colorScheme == .dark) }

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if let art = music.artwork {
                    Image(uiImage: art).resizable().scaledToFill()
                } else {
                    palette.accentGradient
                }
            }
            .frame(width: 38, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(music.title).font(.system(.subheadline, design: .rounded).weight(.semibold)).lineLimit(1)
                Text(music.artist).font(.caption).foregroundColor(palette.inkSoft).lineLimit(1)
            }
            .foregroundColor(palette.ink)
            Spacer(minLength: 4)
            Button { music.toggle() } label: {
                Image(systemName: music.isPlaying ? "pause.fill" : "play.fill").font(.title3).frame(width: 34, height: 34)
            }
            Button { music.next() } label: {
                Image(systemName: "forward.fill").font(.body).frame(width: 34, height: 34)
            }
        }
        .foregroundColor(palette.rose)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .candelaSurface(radius: 22)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
    }
}

// MARK: - Full player

struct CandelaMusicView: View {
    @ObservedObject var music: CandelaMusic = .shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var seek: Double = 0
    @State private var scrubbing = false
    private var palette: CandelaPalette { CandelaPalette(dark: colorScheme == .dark) }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 22) {
                    if music.status == .authorized {
                        nowPlaying
                        library
                    } else {
                        permission
                    }
                }
                .padding()
            }
            .themedBackground()
            .navigationTitle("Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    private var permission: some View {
        VStack(spacing: 14) {
            Image(systemName: "music.note.list").font(.system(size: 44)).foregroundColor(palette.rose)
            Text("Play your music while you game")
                .font(.system(.title3, design: .rounded).weight(.semibold)).foregroundColor(palette.ink)
            Text("Candela can play the songs and playlists in your Music library. Allow access to get started.")
                .font(.subheadline).foregroundColor(palette.inkSoft).multilineTextAlignment(.center)
            Button("Allow Music access") {
                if music.status == .denied {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                } else {
                    music.requestAccess()
                }
            }
            .buttonStyle(CandelaPrimaryButtonStyle())
        }
        .padding(.top, 40)
    }

    private var nowPlaying: some View {
        VStack(spacing: 14) {
            Group {
                if let art = music.artwork {
                    Image(uiImage: art).resizable().scaledToFill()
                } else {
                    palette.accentGradient.overlay(Image(systemName: "music.note").font(.system(size: 54)).foregroundColor(.white.opacity(0.85)))
                }
            }
            .frame(width: 230, height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: palette.rose.opacity(colorScheme == .dark ? 0 : 0.28), radius: 14, x: 0, y: 8)

            VStack(spacing: 3) {
                Text(music.hasItem ? music.title : "Nothing playing")
                    .font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(palette.ink).lineLimit(1)
                if !music.artist.isEmpty { Text(music.artist).font(.subheadline).foregroundColor(palette.inkSoft) }
            }

            Slider(value: Binding(get: { scrubbing ? seek : music.progress }, set: { seek = $0 }), in: 0...1) { editing in
                scrubbing = editing
                if !editing { music.seek(to: seek) }
            }
            .tint(palette.rose)

            HStack(spacing: 34) {
                Button { music.previous() } label: { Image(systemName: "backward.fill").font(.title2) }
                Button { music.toggle() } label: { Image(systemName: music.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 56)) }
                Button { music.next() } label: { Image(systemName: "forward.fill").font(.title2) }
            }
            .foregroundColor(palette.rose)
        }
    }

    private var library: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !music.playlists.isEmpty {
                CandelaSectionTitle("Playlists")
                ForEach(music.playlists, id: \.persistentID) { list in
                    row(title: list.name ?? "Playlist", count: list.count, collection: list)
                }
            }
            if !music.albums.isEmpty {
                CandelaSectionTitle("Albums")
                ForEach(music.albums.prefix(60), id: \.persistentID) { album in
                    row(title: album.representativeItem?.albumTitle ?? "Album", count: album.count, collection: album)
                }
            }
            if music.playlists.isEmpty && music.albums.isEmpty {
                Text("No music found. Download songs in the Music app and they show up here.")
                    .font(.footnote).foregroundColor(palette.inkSoft)
            }
        }
    }

    private func row(title: String, count: Int, collection: MPMediaItemCollection) -> some View {
        Button { music.play(collection) } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(title).foregroundColor(palette.ink).lineLimit(1)
                    Text("\(count) songs").font(.caption).foregroundColor(palette.inkSoft)
                }
                Spacer()
                Image(systemName: "play.fill").foregroundColor(palette.rose)
            }
            .padding(12)
            .candelaSurface(radius: 14)
        }
        .buttonStyle(.plain)
        .contextMenu { Button("Shuffle") { music.shuffle(collection) } }
    }
}
