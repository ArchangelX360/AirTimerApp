import Foundation
import MediaPlayer
import AVFoundation
import Observation

enum TimerDuration: CaseIterable, Identifiable {
    case fiveSeconds
    case fiveMinutes
    case tenMinutes
    case fifteenMinutes
    case endOfChapter
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .fiveSeconds: return "5 sec"
        case .fiveMinutes: return "5 min"
        case .tenMinutes: return "10 min"
        case .fifteenMinutes: return "15 min"
        case .endOfChapter: return "End of chapter"
        }
    }

    var shortLabel: String {
        switch self {
        case .fiveSeconds: return "5 sec"
        case .fiveMinutes: return "5 min"
        case .tenMinutes: return "10 min"
        case .fifteenMinutes: return "15 min"
        case .endOfChapter: return "End"
        }
    }
    
    var backtrackLabel: String {
        switch self {
        case .fiveSeconds: return label
        case .fiveMinutes: return label
        case .tenMinutes: return label
        case .fifteenMinutes: return label
        case .endOfChapter: return "Start"
        }
    }
}

@MainActor
@Observable
class AudioManager {
    private(set) var isPlaying: Bool = false
    private(set) var currentTrack: MPMediaItem?
    private(set) var playbackTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    private(set) var isSleepTimerActive: Bool = false
    private(set) var timeLeft: TimeInterval? = nil
    private(set) var sleepTimer: Timer? = nil
    private var timerUpdatedTask: Task<Void, Never>?

    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var monitoringTask: Task<Void, Never>?
    
    init() {
        updatePlaybackState()
        startMonitoring()
    }
    
    deinit {
        // TODO: how to de-allocate?
        // monitoringTask?.cancel()
        // timerUpdatedTask?.cancel()
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
    
    func backtrack(by duration: TimerDuration) {
        backtrack(by: backtrackPoint(of: duration))
    }

    func startSleepTimer(by duration: TimerDuration) {
        stopSleepTimer()
        if !isPlaying {
            resume()
        }
        
        let updateFrequency = 0.100
        timeLeft = timeLeft(of: duration)
        sleepTimer = Timer.scheduledTimer(withTimeInterval: updateFrequency, repeats: true) { timer in
            Task { @MainActor in
                self.timeLeft = self.timeLeft! - updateFrequency
                if self.timeLeft! <= 0 {
                    self.stopSleepTimer()
                    self.pause()
                }
            }
        }
        isSleepTimerActive = true
    }
    
    func stopSleepTimer() {
        self.isSleepTimerActive = false
        self.sleepTimer?.invalidate()
        self.sleepTimer = nil
    }
    
    private func backtrack(by duration: TimeInterval) {
        let currentTime = musicPlayer.currentPlaybackTime
        let newTime = max(0, currentTime - duration)
        musicPlayer.currentPlaybackTime = newTime
        playbackTime = newTime
    }
    
    private func timeLeft(of duration: TimerDuration) -> TimeInterval {
        switch duration {
        case .fiveSeconds: return 5
        case .fiveMinutes: return 300
        case .tenMinutes: return 600
        case .fifteenMinutes: return 900
        case .endOfChapter: return self.duration - self.playbackTime
        }
    }

    private func backtrackPoint(of duration: TimerDuration) -> TimeInterval {
        switch duration {
        case .fiveSeconds: return 5
        case .fiveMinutes: return 300
        case .tenMinutes: return 600
        case .fifteenMinutes: return 900
        case .endOfChapter: return self.playbackTime
        }
    }
    
    private func startMonitoring() {
        monitoringTask?.cancel()
        
        monitoringTask = Task {
            musicPlayer.beginGeneratingPlaybackNotifications()
            
            // FIXME: MUSIC PLAYER IS NOT AUDIOBOOKS FOR SOME REASON!
            
            let playbackStateStream = NotificationCenter.default.notifications(
                named: .MPMusicPlayerControllerPlaybackStateDidChange,
                object: musicPlayer
            )
            
            let nowPlayingStream = NotificationCenter.default.notifications(
                named: .MPMusicPlayerControllerNowPlayingItemDidChange,
                object: musicPlayer
            )
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await _ in playbackStateStream {
                        await self.updatePlaybackState()
                    }
                }
                
                group.addTask {
                    for await _ in nowPlayingStream {
                        await self.updateCurrentTrack()
                    }
                }
                
                group.addTask {
                    await self.startPlaybackTimer()
                }
            }
        }
    }
    
    private func startPlaybackTimer() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(500))
            if isPlaying {
                updatePlaybackTime()
            }
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
    
    private func updatePlaybackTime() {
        guard isPlaying else { return }
        playbackTime = musicPlayer.currentPlaybackTime
    }
}
