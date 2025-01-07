import Speech
import AVFoundation
import AVKit

class SnellenSpeechHandler: NSObject, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate, ObservableObject {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var speechCompletionContinuation: CheckedContinuation<Void, Never>?
    
    // Flag to ignore recognition results while TTS is speaking
    private var shouldIgnoreResults = false
    
    private var lastRecognizedLetter: String?
    private var lastRecognitionTime: Date?
    private let recognitionCooldown: TimeInterval = 1.0
    
    private let snellenLetters = Set(["E", "F", "P", "T", "O", "Z", "L", "D"])
    private let validLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }
    var onLetterRecognized: ((String) -> Void)?
    
    // Use for auditory cues
    private let synthesizer = AVSpeechSynthesizer()
    
    // Current recording mode
    private enum RecognitionMode {
        case letter
        case confirmation(letterToConfirm: String)
    }
    private var currentMode: RecognitionMode = .letter
    private let confirmationPhrases = ["yes", "yeah", "correct", "right", "no", "nope", "incorrect", "wrong"]
    
    // Keeps track of segments we've already processed
    private var lastProcessedSegmentIndex: Int = 0
    
    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        
        Logger.rlog("Initializing SnellenSpeechRecognizer")
        speechRecognizer?.delegate = self
        synthesizer.delegate = self  // so we know when TTS finishes
    }
    
    func startRecording() {
        Logger.rlog("Requesting speech recognition authorization...")
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
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
                }
            }
        }
    }
    
    /// Creates a single recording session
    private func startRecordingSession() throws {
        Logger.group("Starting recording session")
        
        // Clean up if something’s leftover
        cleanupRecordingSession()
        
        // Reset our processed-segments index for a fresh session
        lastProcessedSegmentIndex = 0
        
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
        
        // Create the request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SnellenSpeechRecognizer", code: -1, userInfo: nil)
        }
        
        // Bias the recognizer towards letters or yes/no confirms
        switch currentMode {
        case .letter:
            recognitionRequest.contextualStrings = validLetters
        case .confirmation:
            recognitionRequest.contextualStrings = confirmationPhrases
        }
        recognitionRequest.shouldReportPartialResults = true
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw NSError(domain: "SnellenSpeechRecognizer", code: -2, userInfo: nil)
        }
        
        // Create the recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                Logger.log("Recognition task error: \(error.localizedDescription)")
                return
            }
            if let result = result {
                self.handleRecognitionResult(result)
            }
        }
        
        // Install audio tap
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        Logger.log("Installing audio tap...")
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        lastRecognitionTime = Date()
        Logger.groupEnd("Recording session started successfully")
    }
    
    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult) {
        // If ignoring results while TTS is speaking, bail out
        if shouldIgnoreResults { return }
        
        Logger.log("Full transcription: \(result.bestTranscription.formattedString)")
        
        let segments = result.bestTranscription.segments
        
        // Process only new segments that haven't been handled yet
        guard lastProcessedSegmentIndex < segments.count else {
            // Nothing new
            return
        }
        let newSegments = Array(segments[lastProcessedSegmentIndex..<segments.count])
        
        // Mark these segments as processed
        lastProcessedSegmentIndex = segments.count
        
        // Now pass only these new segments to the relevant handlers
        switch currentMode {
        case .letter:
            handleLetterRecognition(newSegments)
        case .confirmation(let letterToConfirm):
            handleConfirmationRecognition(newSegments, forLetter: letterToConfirm)
        }
    }
    
    private func handleLetterRecognition(_ segments: [SFTranscriptionSegment]) {
        for segment in segments {
            Logger.log("Letter segment: \(segment.substring)")
            let letter = segment.substring.uppercased()
            if letter.count == 1 && validLetters.contains(letter) {
                // Check cooldown if same letter repeated too fast
                let now = Date()
                if let lastTime = lastRecognitionTime,
                   let lastLetter = lastRecognizedLetter,
                   lastLetter == letter,
                   now.timeIntervalSince(lastTime) < recognitionCooldown {
                    return
                }
                
                lastRecognizedLetter = letter
                lastRecognitionTime = now
                Logger.log("Valid letter recognized: \(letter)")
                
                // Pause, prompt user for confirmation
                Task {
                    await askUserForConfirmation(letter: letter)
                }
                return
            }
        }
    }
    
    private func handleConfirmationRecognition(_ segments: [SFTranscriptionSegment], forLetter letter: String) {
        for segment in segments {
            Logger.log("Confirmation segment: \(segment.substring)")
            let response = segment.substring.lowercased()
            
            if ["yes", "yeah", "correct", "right"].contains(response) {
                Logger.log("User confirmed letter \(letter)")
                currentMode = .letter
                onLetterRecognized?(letter)
                return
            }
            
            if ["no", "nope", "incorrect", "wrong"].contains(response) {
                Logger.log("User rejected letter \(letter)")
                currentMode = .letter
                return
            }
        }
    }
    
    private func pauseAudioEngine() {
        Logger.log("Pausing audio engine (without ending audio)")
        audioEngine.pause()            // Does not remove tap or end the request
        shouldIgnoreResults = true     // We'll ignore partial results during TTS
    }
    
    private func resumeAudioEngine() throws {
        Logger.log("Resuming audio engine")
        audioEngine.prepare()
        try audioEngine.start()
        shouldIgnoreResults = false
    }
    
    /// Clean up the session entirely
    private func cleanupRecordingSession() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Reset the processed-segment index in case we create a new session later
        lastProcessedSegmentIndex = 0
    }
    
    func stopRecording() {
        cleanupRecordingSession()
        Logger.rlog("Recording stopped")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Optionally wait a moment before re-enabling
        Task {
            do {
                // Give the user a short delay to avoid speaking over TTS
                try await Task.sleep(nanoseconds: 700_000_000) // 0.7s delay
                try resumeAudioEngine()
            } catch {
                Logger.log("Failed to resume audio engine: \(error)")
            }
        }
        
        // If you’re using withCheckedContinuation, resume it here
        speechCompletionContinuation?.resume()
        speechCompletionContinuation = nil
    }
    
    func askUserForConfirmation(letter: String) async {
        pauseAudioEngine()
        
        // Switch to confirmation mode
        currentMode = .confirmation(letterToConfirm: letter)
        
        let utterance = AVSpeechUtterance(string: "Is this the correct letter, \(letter)?")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        return await withCheckedContinuation { continuation in
            speechCompletionContinuation = continuation
            
            // If TTS is already speaking, stop it first
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
            }
            
            synthesizer.speak(utterance)
            Logger.rlog("Speaking confirmation message for letter: \(letter)")
        }
    }
}
