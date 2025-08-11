import SwiftUI

struct TimerView: View {
    private var audioManager = AudioManager()
    @State private var showingDurationPicker = false
    private var selectedDurationBinding: Binding<TimerDuration> {
        Binding(
            get: { audioManager.selectedDuration },
            set: { audioManager.selectedDuration = $0 }
        )
    }
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                Button(action: {
                    audioManager.isSleepTimerActive ? audioManager.stopSleepTimer() : audioManager.startSleepTimer(by: audioManager.selectedDuration)
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                            .shadow(color: .primary.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 60))
                                .foregroundColor(audioManager.isSleepTimerActive ? .accentColor : .primary)
                        }
                    }
                }
                .scaleEffect(audioManager.isSleepTimerActive ? 0.99 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: audioManager.isSleepTimerActive)
                
                Spacer()
                
                Text(Duration(secondsComponent: Int64(audioManager.timeLeft ?? 0), attosecondsComponent: 0).formatted(.time(pattern: .minuteSecond)))
                    .opacity(audioManager.isSleepTimerActive ? 1 : 0)
                    .font(.system(size: 60).monospacedDigit())
                    .foregroundColor(.primary)
                
                Spacer()
                
                VStack(spacing: 20) {
                    HStack(spacing: geometry.size.width * 0.4 / 3) {
                        
                        Button(action: { audioManager.toggleRestartTimerOnPlay() }) {
                            VStack(spacing: 4) {
                                Image(systemName: "point.forward.to.point.capsulepath")
                                    .font(.title3)
                                Text("Auto")
                                    .font(.caption)
                            }
                            .foregroundColor(audioManager.restartTimerOnPlay ? .accentColor : .primary)
                        }
                        
                        // Button(action: { audioManager.backtrack(by: audioManager.selectedDuration) }) {
                        //     VStack(spacing: 4) {
                        //         Image(systemName: "gobackward")
                        //             .font(.title3)
                        //         Text(audioManager.selectedDuration.backtrackLabel)
                        //             .font(.caption)
                        //     }
                        //     .foregroundColor(.secondary)
                        // }
                        // .disabled(true)
                        
                        Button(action: { showingDurationPicker = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.title3)
                                Text(audioManager.selectedDuration.shortLabel)
                                    .font(.caption)
                            }
                            .foregroundColor(.primary)
                        }
                        
                        Button(action: togglePlayback) {
                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(width: geometry.size.width * 0.55, height: 50)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
                    .shadow(color: .primary.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingDurationPicker) { // TODO: should be nice not to be a sheet, but a pop-up like Apple Books
            DurationPickerView(selectedDuration: selectedDurationBinding)
        }
    }
    
    private func togglePlayback() {
        if audioManager.isPlaying {
            audioManager.pause()
        } else {
            audioManager.resume()
        }
    }
}

struct DurationPickerView: View {
    @Binding var selectedDuration: TimerDuration
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(TimerDuration.allCases) { duration in
                let disabled = duration == TimerDuration.endOfChapter // FIXME: remove when supported
                Button(action: {
                    selectedDuration = duration
                    dismiss()
                }) {
                    HStack {
                        Text(duration.label)
                            .foregroundColor(disabled ? .secondary : .primary)
                        Spacer()
                        if selectedDuration == duration {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }.disabled(disabled)
            }
            .navigationTitle("Timer Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    TimerView()
}
