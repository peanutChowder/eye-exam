import Speech
import AVFoundation

class SnellenSpeechRecognizer: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let validLetters = Set(["E", "F", "P", "T", "O", "Z", "L", "D"])
    var onLetterRecognized: ((String) -> Void)?
    
    private var lastSpeechTime: Date?
    private let silenceThreshold: TimeInterval = 30.0
    private var silenceTimer: Timer?
    
    // Add a flag to track if we're in the process of restarting
    private var isRestarting = false
    
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
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
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
                let text = result.bestTranscription.formattedString.uppercased()
                Logger.log("Recognition result: \(text)")
                
                for letter in text.components(separatedBy: " ") {
                    if letter.count == 1 && self.validLetters.contains(letter) {
                        Logger.log("Valid letter recognized: \(letter)")
                        self.lastSpeechTime = Date()
                        self.onLetterRecognized?(letter)
                        
                        // Set the restart flag before cleanup
                        self.isRestarting = true
                        
                        // Clean up and restart with a slight delay
                        self.cleanupRecordingSession()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            do {
                                try self.startRecordingSession()
                            } catch {
                                Logger.log("Failed to restart recording session: \(error)")
                            }
                        }
                        return
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
}
