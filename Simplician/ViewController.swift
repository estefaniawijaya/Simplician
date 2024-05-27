import AVFoundation
import SoundAnalysis

class ViewController: UIViewController {

    let audioEngine = AVAudioEngine()
    var inputFormat: AVAudioFormat!
    var analyzer: SNAudioStreamAnalyzer!
    var request: SNClassifySoundRequest!
    var resultsObserver: ResultsObserver!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup audio engine
        inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        analyzer = SNAudioStreamAnalyzer(format: inputFormat)

        // Create a classification request
        request = try! SNClassifySoundRequest(mlModel: SoundClassifier().model)
        resultsObserver = ResultsObserver()
        try! analyzer.add(request, withObserver: resultsObserver)

        // Request microphone access and start audio session
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                self.startAudioEngine()
            } else {
                // Handle the case where the user denies microphone access
            }
        }
    }

    func startAudioEngine() {
        let inputNode = audioEngine.inputNode
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { (buffer, time) in
            self.analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
        }
        audioEngine.prepare()
        try! audioEngine.start()
    }
}

class ResultsObserver: NSObject, SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }

        // Process the classification result
        let classification = result.classifications.first
        let confidence = classification?.confidence ?? 0
        let identifier = classification?.identifier ?? ""

        print("Sound: \(identifier), Confidence: \(confidence)")
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("Sound analysis request failed: \(error.localizedDescription)")
    }

    func requestDidComplete(_ request: SNRequest) {
        print("Sound analysis request completed.")
    }
}
