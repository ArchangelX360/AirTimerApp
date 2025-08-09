import Foundation
import MediaPlayer
import AVFoundation

@MainActor
class AudioManager: ObservableObject {
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTrack: MPMediaItem?
    @Published private(set) var playbackTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var playbackTimer: Timer?
    
    init() {
        setupNotifications()
        updatePlaybackState()
        startPlaybackTimer()
    }
    
    deinit {
        stopPlaybackTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStateChanged),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer
        )
        
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    @objc private func playbackStateChanged() {
        Task { @MainActor in
            updatePlaybackState()
        }
    }
    
    @objc private func nowPlayingItemChanged() {
        Task { @MainActor in
            updateCurrentTrack()
        }
    }
    
    private func updatePlaybackState() {
        isPlaying = musicPlayer.playbackState == .playing
        playbackTime = musicPlayer.currentPlaybackTime
        
        if let item = musicPlayer.nowPlayingItem {
            duration = item.playbackDuration
        }
    }
    
    private func updateCurrentTrack() {
        currentTrack = musicPlayer.nowPlayingItem
        updatePlaybackState()
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePlaybackTime()
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updatePlaybackTime() {
        guard isPlaying else { return }
        playbackTime = musicPlayer.currentPlaybackTime
    }
    
    func getCurrentlyPlayingAudio() -> MPMediaItem? {
        return musicPlayer.nowPlayingItem
    }
    
    func resume() {
        musicPlayer.play()
    }
    
    func pause() {
        musicPlayer.pause()
    }
    
    func backtrack(by duration: TimeInterval) {
        let currentTime = musicPlayer.currentPlaybackTime
        let newTime = max(0, currentTime - duration)
        musicPlayer.currentPlaybackTime = newTime
        playbackTime = newTime
    }
    
    func seek(to time: TimeInterval) {
        let clampedTime = max(0, min(time, duration))
        musicPlayer.currentPlaybackTime = clampedTime
        playbackTime = clampedTime
    }
    
    func skipForward(by duration: TimeInterval) {
        let currentTime = musicPlayer.currentPlaybackTime
        let newTime = min(self.duration, currentTime + duration)
        musicPlayer.currentPlaybackTime = newTime
        playbackTime = newTime
    }
}

extension AudioManager {
    var formattedCurrentTime: String {
        return formatTime(playbackTime)
    }
    
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}