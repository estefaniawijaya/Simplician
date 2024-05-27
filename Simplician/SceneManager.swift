import SwiftUI
import AVKit
import Combine

struct SceneManager: View {
    @State private var AmOpacity: Double = 0.0
    @State private var COpacity: Double = 0.0
    @State private var GOpacity: Double = 0.0
    @State private var showingSplash = true
    @State private var showingChordAmView = false
    @State private var showingChordCView = false
    @State private var showingChordGView = false
    @State private var remainingTime = 30
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        ZStack {
            if showingSplash {
                if let videoURL = Bundle.main.url(forResource: "Simplician-2", withExtension: "mp4") {
                                    VideoPlayerView(player: AVPlayer(url: videoURL))
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 3.2, repeats: false) { _ in
                                showingSplash = false
                                showingChordAmView = true
                            }
                        }
                                    
                                } else {
                                    Text("Video not found")
                                        .foregroundColor(.white)
                                        .background(Color.black)
                                }
                    
            }
            
            if showingChordAmView {
                ChordAmView()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(AmOpacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.5)) {
                            AmOpacity = 1.0
                            showingChordAmView = true
                        }
                        remainingTime = 30
                        Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
                            showingChordAmView = false
                            showingChordCView = true
                        }
                    }
            }

            if showingChordCView {
                ChordCView2()
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.5)) {
                            COpacity = 1.0
                            showingChordCView = true
                        }
                        remainingTime = 30
                        Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
                            showingChordCView = false
                            showingChordGView = true
                        }
                    }
            }

            if showingChordGView {
                ChordGView()
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.5)) {
                            GOpacity = 1.0
                            showingChordGView = true
                        }
                        remainingTime = 30
                    }
            }

            HStack {
                Spacer()
                VStack {
                    Text("\(remainingTime)s")
                        .font(.system(size: 18, weight: .bold))
                        
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                        .padding(.top, 50) // Top padding
                        .padding(.trailing, 40)
                    Spacer()
                }
            }
        }
        .onReceive(timer) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            }
        }
        .ignoresSafeArea(.all)
    }
}

#Preview {
    SceneManager()
}

