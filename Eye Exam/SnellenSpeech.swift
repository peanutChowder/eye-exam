import Speech
import AVFoundation

class SnellenSpeechRecognizer: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Valid Snellen chart letters
    private let validLetters = Set(["E", "F", "P", "T", "O", "Z", "L", "D"])
    
    // Callback for when a letter is recognized
    var onLetterRecognized: ((String) -> Void)?
    
    // Track silence for auto-stopping
    private var lastSpeechTime: Date?
    private let silenceThreshold: TimeInterval = 30.0 //seconds
    private var silenceTimer: Timer?
    
    override init() {
        super.init()
        speechRecognizer.delegate = self
        setupSilenceDetection()
    }
    
    private func setupSilenceDetection() {
        // Monitor audio levels for silence detection
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self,
                  let lastSpeech = self.lastSpeechTime,
                  Date().timeIntervalSince(lastSpeech) >= self.silenceThreshold else {
                return
            }
            
            // Stop recording after silence threshold
            Logger.rlog("Silence threshold reached")
            self.stopRecording()
        }
    }
    
    func startRecording() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                guard authStatus == .authorized else {
                    Logger.rlog("Speech recognition not authorized")
                    return
                }
                
                do {
                    try self.startRecordingSession()
                } catch {
                    Logger.rlog("Failed to start recording: \(error)")
                }
            }
        }
    }
    
    private func startRecordingSession() throws {
        // Reset existing tasks
        recognitionTask?.cancel()
        recognitionTask = nil
        
        Logger.rlog("Started speech recording")
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        Logger.log("Beginning speech recognition")
        
        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let text = result.bestTranscription.formattedString.uppercased()
                
                Logger.rlog("Letter: \(text)")
                
                // Check for valid letters in the transcription
                for letter in text.components(separatedBy: " ") {
                    if letter.count == 1 && self.validLetters.contains(letter) {
                        self.lastSpeechTime = Date()
                        self.onLetterRecognized?(letter)
                    }
                }
            }
            
            if error != nil {
                Logger.log("Error: \(String(describing: error))")
                self.stopRecording()
            }
        }
        
        lastSpeechTime = Date()
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        Logger.rlog("Recording stopped")
    }
}
