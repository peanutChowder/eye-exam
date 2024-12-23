import Speech
import AVFoundation
import AVKit

class SnellenSpeechHandler: NSObject, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate, ObservableObject {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var speechCompletionContinuation: CheckedContinuation<Void, Never>?

    
    private let snellenLetters = Set(["E", "F", "P", "T", "O", "Z", "L", "D"])
    private let validLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }
    var onLetterRecognized: ((String) -> Void)?
    
    private var lastSpeechTime: Date?
    private let silenceThreshold: TimeInterval = 30.0
    private var silenceTimer: Timer?
    
    // Add a flag to track if we're in the process of restarting
    private var isRestarting = false
    
    // Use for auditory cues to user
    private let synthesizer = AVSpeechSynthesizer()

    
    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        
        Logger.rlog("Initializing SnellenSpeechRecognizer")
        if speechRecognizer == nil {
            Logger.rlog("ERROR: Failed to initialize speech recognizer")
        }
        speechRecognizer?.delegate = self
    }
    
    func startRecording() {
        Logger.rlog("Requesting speech recognition authorization...")
        
        // Reset the restart flag
        isRestarting = false
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else {
                Logger.rlog("Self was deallocated during authorization")
                return
            }
            
            DispatchQueue.main.async {
                Logger.rlog("Authorization status received: \(authStatus.rawValue)")
                
                guard authStatus == .authorized else {
                    Logger.rlog("Speech recognition not authorized. Status: \(authStatus)")
                    return
                }
                
                do {
                    try self.startRecordingSession()
                } catch {
                    Logger.rlog("Failed to start recording session: \(error.localizedDescription)")
                    Logger.rlog("Error domain: \(error._domain)")
                    Logger.rlog("Error code: \(error._code)")
                }
            }
        }
    }
    
    private func startRecordingSession() throws {
        Logger.group("Starting recording session")
        
        // Ensure clean state before starting
        self.cleanupRecordingSession()
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            Logger.log("Configuring audio session...")
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            Logger.log("Audio session configuration failed: \(error.localizedDescription)")
            throw error
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard recognitionRequest != nil else {
            Logger.log("ERROR: Unable to create recognition request")
            throw NSError(domain: "SnellenSpeechRecognizer", code: -1, userInfo: nil)
        }
        
        // Bias the recognizer towards all letters
        recognitionRequest?.contextualStrings = validLetters

        // Optional: Set task hint to dictation for better accuracy with single letters
        recognitionRequest?.taskHint = .dictation
        
        recognitionRequest?.shouldReportPartialResults = true
        
        guard let speechRecognizer = speechRecognizer else {
            Logger.log("ERROR: Speech recognizer is nil")
            throw NSError(domain: "SnellenSpeechRecognizer", code: -2, userInfo: nil)
        }
        
        guard speechRecognizer.isAvailable else {
            Logger.log("ERROR: Speech recognizer is not available")
            throw NSError(domain: "SnellenSpeechRecognizer", code: -3, userInfo: nil)
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        Logger.log("Installing audio tap...")
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        do {
            Logger.log("Preparing audio engine...")
            audioEngine.prepare()
            try audioEngine.start()
            Logger.log("Audio engine started successfully")
        } catch {
            Logger.log("Failed to start audio engine: \(error.localizedDescription)")
            throw error
        }
        
        Logger.log("Starting recognition task...")
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                Logger.log("Recognition task error: \(error.localizedDescription)")
                Logger.log("Error domain: \(error._domain)")
                Logger.log("Error code: \(error._code)")
                
                // Only handle cleanup if we're not already restarting
                if !self.isRestarting {
                    self.cleanupRecordingSession()
                }
                return
            }
            
            if let result = result {
                let segments = result.bestTranscription.segments
                
                for segment in segments {
                    let letter = segment.substring.uppercased()
                    if letter.count == 1 && self.validLetters.contains(letter) {
                        Logger.log("Valid letter recognized: \(letter)")
                        self.lastSpeechTime = Date()
                        self.onLetterRecognized?(letter)
                        
                        // Set the restart flag before cleanup
                        self.isRestarting = true
                        
                        // Task for the speech
                        Task {
                            await self.askUserForConfirmation(letter: letter)
                            
                            // delay to make sure speech finishes talking
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            
                            self.cleanupRecordingSession()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                do {
                                    try self.startRecordingSession()
                                } catch {
                                    Logger.log("Failed to restart recording session: \(error)")
                                }
                            }
                        }
                        return
                    } else {
                        Logger.log("Invalid segment: \(segment.substring)")
                    }
                }
            }
        }
        
        lastSpeechTime = Date()
        Logger.groupEnd("Recording session started successfully")
    }
    
    private func cleanupRecordingSession() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            Logger.rlog("Recording cleanup error: \(error)")
        }
        
        Logger.rlog("Cleanup done")
        Logger.groupEnd()
    }
    
    func stopRecording() {
        cleanupRecordingSession()
        Logger.rlog("Recording stopped")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        do {
            // Resume recording
            try audioEngine.start()
        } catch {
            Logger.rlog("Failed to resume audio engine: \(error)")
        }
        
        speechCompletionContinuation?.resume()
        speechCompletionContinuation = nil
    }
    
    func askUserForConfirmation(letter: String) async {
        // Stop recording temporarily
        audioEngine.pause()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        let utterance = AVSpeechUtterance(string: "Did you say this letter, \(letter)?")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        return await withCheckedContinuation { continuation in
            synthesizer.delegate = self
            speechCompletionContinuation = continuation
            
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
            }
            
            synthesizer.speak(utterance)
            Logger.rlog("Spoke message for letter: \(letter)")
        }
    }
}
