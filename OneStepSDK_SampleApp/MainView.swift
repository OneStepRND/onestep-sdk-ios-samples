//
//  ContentView.swift
//  OneStepSDK_SampleApp
//
//  Created by David Havkin on 01/08/2024.
//

import SwiftUI
import Combine
import OneStepSDK

struct MainView: View {
    let sdk = OneStepSDKCore.shared
    let recorder: OneStepSimpleRecorderProtocol
    @State var recordingInProgress: Bool = false
    @State var isLoadingResult: Bool = false
    @State var failedToAnalyze = false
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    @State var walkScore: Int? = nil
    @State var stepsCount: Int? = nil
    @State var time: Int = 0
    @State var currentRecordingUUID: UUID? = nil
    @State var cancellables = Set<AnyCancellable>()
    @State var recorderState = "Initial"
    
    init(){
        self.recorder = self.sdk.getRecorderService()
    }
    
    //Fill in your details before you can successfully start the app.
    func connectUser() {
        Task{
            try? await sdk.initialize(appId: "<YOUR-APP-ID-HERE>",
                                      apiKey: "<YOUR-API-KEY-HERE>",
                                      distinctId: "<A-UUID-FOR CURRENT-USER-HERE>")
        }
    }
    
    var body: some View {
        VStack {
            Text("OneStep Walk recorder")
                .font(.title)
                .padding(.top, 20)
                .padding(.bottom, 70)
            CustomButton(
                title: recordingInProgress ? "Stop and analyze" : "Start recording",
                action: {
                    recordingInProgress ?
                    stopInAppRecordingAndUpload() :
                    startRecording()
                },
                isActivated: recordingInProgress, height: 100)
            .padding(.bottom, 30)
            
            Text("Timer: \(time)")
                .padding(.bottom, 10)
                .font(.largeTitle)
            
            Text("Recorder state: \(recorderState)")
                .padding(.bottom, 10)
                .font(.title3)
            
            if let ws = walkScore, let st = stepsCount {
                VStack{
                    Text("Your walk score: \(ws)")
                    Text("Your steps count: \(st)")
                }
                .font(.title)
            } else if isLoadingResult {
                Text("Here will appear result. Please wait...")
                    .font(.title2)
                    .padding(10)
                ActivityIndicator(isAnimating: isLoadingResult)
                    .background(Color.black)
                    .frame(width: 50, height: 50)
            } else if failedToAnalyze {
                Text("Did not get either walk score or steps count. \n Perform a real walk of at least 30 seconds, please.")
                    .font(.title2)
            }
            Spacer()
        }
        .padding()
        .onAppear{
            self.connectUser()
        }
    }
    
    /// Start recording a new session: timed walk (60 seconds - parameter set inside).
    ///
    /// Developer responsibility: handling recorder state machine (i.e not calling `start` when already recording)
    /// Developer responsibility: Making sure that motion and location permissions are granted and usage descriptions are in place in info.plist
    ///
    func startRecording() {
        failedToAnalyze = false
        walkScore = nil
        stepsCount = nil
        time = 0
        self.recorder.start(activityType: .Walk, duration: 60, userInputMetadata: nil, customMetadata: nil)
        recordingInProgress = true
        startRecordingTimer()
        
        self.recorder.recorderState.receive(on: RunLoop.main).sink(receiveValue: { recorderState in
            self.recorderState = "\(recorderState)"
            switch recorderState {
            case .recording(let recordingUUID):
                self.currentRecordingUUID = recordingUUID
            case.finishedRecording:
                if let uuid = self.currentRecordingUUID {
                    self.recorder.analyze(uuid: uuid)
                }
                recordingInProgress = false
                self.recorder.reset()
            case .analyzedAndSavedSuccessfully:
                if let uuid = self.currentRecordingUUID {
                    let result = self.recorder.getSummaryForMeasurement(uuid: uuid)
                    if let walkScore = result?.parameters?["walk_score"], let steps = result?.metadata?.steps{
                        self.walkScore = Int(walkScore)
                        self.stepsCount = steps
                    } else {
                        failedToAnalyze = true
                    }
                    self.recorderState = "Initial"
                }
            case .error(let errorType):
                //Do something based on error type
                break
            default:
                break
            }
        }).store(in: &cancellables)
    }
    
    //Manually stop recording before duration time is out.
    func stopInAppRecordingAndUpload() {
        recordingInProgress = false
        isLoadingResult = true
        
        recorder.stop()
        cancellables.removeAll()
    }
    
    private func startRecordingTimer() {
        timer.map({ (date) -> Void in
            time += 1
        })
        .sink { _ in
            if !recordingInProgress {
                timer.upstream.connect().cancel()
            }
        }
        .store(in: &cancellables)
    }
}

#Preview {
    MainView()
}

struct CustomButton: View {
    @Environment(\.isEnabled) var isEnabled
    let title: String
    let action: () -> Void
    let isActivated: Bool?
    let height: CGFloat
    
    init(title: String, action: @escaping () -> Void, isActivated: Bool? = nil, height: CGFloat = 50) {
        self.title = title
        self.action = action
        self.isActivated = isActivated
        self.height = height
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
                .foregroundStyle(Color.white)
                .padding(15)
                .frame(minWidth: 300, minHeight: height)
                .background(isEnabled ? isActivated == true ? Color.red : Color.green : .gray)
                .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

struct ActivityIndicator: UIViewRepresentable {
    typealias UIView = UIActivityIndicatorView
    var isAnimating: Bool
    fileprivate var configuration = { (indicator: UIView) in }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView { UIView() }
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        configuration(uiView)
    }
}
