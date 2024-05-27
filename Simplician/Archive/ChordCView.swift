import SwiftUI
import AVFoundation
import CoreML

struct ChordCView: View {
    @State private var greenFingerOpacity: Double = 0.0
    @State private var micOpacity: Double = 0.0
    @State private var micIconOpacity: Double = 0.0
    @State private var checkIconOpacity: Double = 0.0
    @State private var isMicVisible: Bool = false
    @State private var isMicIconVisible: Bool = false
    @State private var isCheckIconVisible: Bool = false
    @State private var canShowGreenFinger: Bool = false
    @State private var canShowMic: Bool = false
    @State private var canShowCheck: Bool = false
    @State private var isRecording = false
    @State private var isMicrophonePaused = false // New state variable

    let audioEngine = AVAudioEngine()
    let audioSession = AVAudioSession.sharedInstance()

    let model: UkuleleSoundClassifier_3 = {
        do {
            let config = MLModelConfiguration()
            return try UkuleleSoundClassifier_3(configuration: config)
        } catch {
            print("Failed to load model: \(error)")
            fatalError("Couldn't create YourModel")
        }
    }()

    var body: some View {
        ZStack {
                ZStack {
                    Image("C")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(.all)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeIn(duration: 0.5)) {
//                                    startRecording() // Resume recording when green finger is shown
                                }
                            }
                        }

                        Image("GreenFinger")
                            .position(x: 639, y: 570)
                            .opacity(greenFingerOpacity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation(.easeIn(duration: 0.5)) {
                                        greenFingerOpacity = 1.0
                                    }
                                        startRecording() // Resume recording when green finger is shown
                                }
                            }
                    
                }
            
            if canShowMic {
                Image("Mic")
                    .opacity(micOpacity)

                Image(systemName: "mic.fill")
                    .position(x: 600, y: 360)
                    .font(.system(size: 140))
                    .foregroundColor(.white)
                    .opacity(micIconOpacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.5)) {
                            micOpacity = 1.0
                            isMicVisible = true
                            micIconOpacity = 1.0
                            isMicIconVisible = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    micOpacity = 0.0
                                    isMicVisible = false
                                    micIconOpacity = 0.0
                                    isMicIconVisible = false
                                }
                            }
                        }

                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            requestMicrophonePermission()
                        }
                    }
                // code for record

            }

            if canShowCheck {
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Image(systemName: "checkmark.circle.fill")
                        .position(x: 600, y: 390)
                        .font(.system(size: 200))
                        .foregroundColor(.green)
                        .opacity(checkIconOpacity)

                }
                .onAppear {
                    stopRecording() // Stop recording when check icon is shown
                    withAnimation(.easeIn(duration: 1.0)) {
                        checkIconOpacity = 1.0
                        isCheckIconVisible = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            checkIconOpacity = 0.0
                            isCheckIconVisible = false
                        }
                    }
                }
            }


            // Full-screen tap gesture
            Color.clear
                .contentShape(Rectangle()) // Makes the whole area tappable
                
                .ignoresSafeArea(.all)
        }
    }

    func requestMicrophonePermission() {
        audioSession.requestRecordPermission { granted in
            if granted {
                setupAudioEngine()
                startRecording()
            } else {
                print("Microphone permission denied")
            }
        }
    }

    func setupAudioEngine() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.inputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            if !isMicrophonePaused {
                // Handle audio buffer here
                // For example, you could analyze the audio levels
                if let channelData = buffer.floatChannelData {
                    let channelDataArray = Array(UnsafeBufferPointer(start: channelData[0], count: Int(buffer.frameLength)))
                    processAudioData(channelDataArray)
                }
            }

            audioEngine.prepare()
        }
    }

    func processAudioData(_ data: [Float]) {
        print("test")
        // Preprocess the data if necessary
        // Pass the data to the model
        do {
            let input = try MLMultiArray(shape: [1, NSNumber(value: data.count)], dataType: .float32)
            for (index, element) in data.enumerated() {
                input[index] = NSNumber(value: element)
            }

            let inputFeatures = UkuleleSoundClassifier_3Input(audioSamples: input)
            let prediction = try model.prediction(input: inputFeatures)
            if let chordKeyValue = prediction.targetProbability.values.max(),
               chordKeyValue > 0.95,
               prediction.target != "Background" {
                if let textFeatureValue = prediction.featureValue(for: "target")?.stringValue {
                    print("Prediction of \(textFeatureValue) with confidence level: \(chordKeyValue)")
                    if textFeatureValue == "C" {
                        DispatchQueue.main.async {
                            canShowCheck = true
                        }
                    }
                }
            }
        } catch {
            print("Failed to make a prediction: \(error)")
        }
    }

    func startRecording() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            try audioEngine.start()
            isRecording = true
            isMicrophonePaused = false // Ensure microphone is not paused
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        isMicrophonePaused = true // Pause the microphone
    }
}

#Preview {
    ChordCView()
}
