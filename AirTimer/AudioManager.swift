import Foundation
import MediaPlayer
import AVFoundation
import Observation

@MainActor
@Observable
class AudioManager {
    var selectedDuration: TimerDuration = .fiveMinutes

    private(set) var isPlaying: Bool = false
    private var playbackTime: TimeInterval = 0
    private var duration: TimeInterval = 0
    private var playbackUpdater: Timer? = nil
    
    private(set) var isSleepTimerActive: Bool = false
    private(set) var timeLeft: TimeInterval? = nil
    private(set) var sleepTimer: Timer? = nil
    
    private(set) var restartTimerOnPlay: Bool = true

    init() {
        startAudioResumeObserver()
        // startPlaybackUpdater()
    }
    
    // bridging MRMediaRemote functions
    private let MRMediaRemoteSendCommand = getMRMediaRemoteSendCommand()!

    func resume() {
        MRMediaRemoteSendCommand(MRMediaRemoteCommandPlay.rawValue, nil)
    }
    
    func pause() {
        MRMediaRemoteSendCommand(MRMediaRemoteCommandPause.rawValue, nil)
    }
    
    func toggleRestartTimerOnPlay() {
        restartTimerOnPlay = !restartTimerOnPlay
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
    
    private func startAudioResumeObserver() {
        // hack start an audio session just to be able to receive events
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            try? session.setActive(true) // ensure active across locks, app-switch, etc.
        }
        try? session.setActive(true)

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.silenceSecondaryAudioHintNotification,
            object: session,
            queue: .main
        ) { note in
            print("received notification \(note)")
            guard
                let raw = note.userInfo?[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
                let type = AVAudioSession.SilenceSecondaryAudioHintType(rawValue: raw)
            else { return }
            
            let otherAppResumedAudio = (type == .begin)
            print("otherAppResumedAudio: \(otherAppResumedAudio)")
            Task { @MainActor in
                self.isPlaying = otherAppResumedAudio
                if otherAppResumedAudio && self.restartTimerOnPlay { // when AirPod play button is pressed for example
                    self.startSleepTimer(by: self.selectedDuration)
                }
            }
        }
        
        self.isPlaying = session.secondaryAudioShouldBeSilencedHint
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
    
    // func backtrack(by duration: TimerDuration) {
    //     backtrack(by: backtrackPoint(of: duration))
    // }
    
    // private func backtrack(by duration: TimeInterval) {
    //     let current = musicPlayer.currentPlaybackTime
    //     let new = max(0, current - duration)
    //     musicPlayer.currentPlaybackTime = new
    //     playbackTime = new
    // }
    
    // private func backtrackPoint(of duration: TimerDuration) -> TimeInterval {
    //     switch duration {
    //     case .fiveSeconds: return 5
    //     case .fiveMinutes: return 300
    //     case .tenMinutes: return 600
    //     case .fifteenMinutes: return 900
    //     case .endOfChapter: return self.playbackTime
    //     }
    // }
    
    // private func startPlaybackUpdater() {
    //     playbackUpdater?.invalidate()
    //     playbackUpdater = Timer.scheduledTimer(withTimeInterval: 0.500, repeats: true) { timer in
    //         Task { @MainActor in
    //             self.isPlaying = self.nowPlaying.playbackState == .playing
    //             if let info = self.nowPlaying.nowPlayingInfo {
    //                 self.playbackTime = (info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as! NSNumber).doubleValue
    //                 self.duration = (info[MPMediaItemPropertyPlaybackDuration] as! NSNumber).doubleValue
    //             }
    //             print("fire")
    //             print(self.isPlaying)
    //             print(self.playbackTime)
    //             print(self.duration)
    //         }
    //     }
    // }
}

