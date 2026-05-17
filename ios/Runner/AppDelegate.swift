import AVFoundation
import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let speechHandler = FitPilotSpeechHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      registerSpeechChannel(messenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func registerSpeechChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "fitpilot/speech", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "listen":
        let args = call.arguments as? [String: Any]
        let localeId = args?["localeId"] as? String ?? "de_DE"
        self.speechHandler.listen(localeId: localeId, result: result)
      case "stop":
        self.speechHandler.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

final class FitPilotSpeechHandler: NSObject {
  private let audioEngine = AVAudioEngine()
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var pendingResult: FlutterResult?
  private var lastTranscription = ""
  private var isFinishing = false
  private var tapInstalled = false

  func listen(localeId: String, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard self.pendingResult == nil else {
        result(FlutterError(
          code: "busy",
          message: "Spracherkennung laeuft bereits.",
          details: nil
        ))
        return
      }
      self.pendingResult = result
      self.lastTranscription = ""
      self.isFinishing = false
      self.requestSpeechAuthorization(localeId: localeId)
    }
  }

  func stop() {
    DispatchQueue.main.async {
      guard self.pendingResult != nil else { return }
      self.finish(success: self.lastTranscription)
    }
  }

  private func requestSpeechAuthorization(localeId: String) {
    SFSpeechRecognizer.requestAuthorization { status in
      DispatchQueue.main.async {
        guard status == .authorized else {
          self.finish(errorCode: "permission_denied", message: "Spracherkennung wurde nicht erlaubt.")
          return
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
          DispatchQueue.main.async {
            guard granted else {
              self.finish(errorCode: "permission_denied", message: "Mikrofon wurde nicht erlaubt.")
              return
            }
            self.startRecognition(localeId: localeId)
          }
        }
      }
    }
  }

  private func startRecognition(localeId: String) {
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId)), recognizer.isAvailable else {
      finish(errorCode: "unavailable", message: "Spracherkennung ist gerade nicht verfuegbar.")
      return
    }

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
      try session.setActive(true, options: .notifyOthersOnDeactivation)

      let request = SFSpeechAudioBufferRecognitionRequest()
      request.shouldReportPartialResults = true
      recognitionRequest = request

      let inputNode = audioEngine.inputNode
      if tapInstalled {
        inputNode.removeTap(onBus: 0)
        tapInstalled = false
      }
      let format = inputNode.outputFormat(forBus: 0)
      inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
        request.append(buffer)
      }
      tapInstalled = true

      recognitionTask = recognizer.recognitionTask(with: request) { [weak self] speechResult, error in
        guard let self = self else { return }
        DispatchQueue.main.async {
          if let speechResult = speechResult {
            self.lastTranscription = speechResult.bestTranscription.formattedString
            if speechResult.isFinal {
              self.finish(success: self.lastTranscription)
              return
            }
          }
          if let error = error {
            if self.lastTranscription.isEmpty {
              self.finish(errorCode: "recognition_failed", message: error.localizedDescription)
            } else {
              self.finish(success: self.lastTranscription)
            }
          }
        }
      }

      audioEngine.prepare()
      try audioEngine.start()
    } catch {
      finish(errorCode: "recognition_failed", message: error.localizedDescription)
    }
  }

  private func finish(success text: String) {
    guard !isFinishing else { return }
    isFinishing = true
    cleanupAudio()
    let result = pendingResult
    pendingResult = nil
    result?(text)
    isFinishing = false
  }

  private func finish(errorCode: String, message: String) {
    guard !isFinishing else { return }
    isFinishing = true
    cleanupAudio()
    let result = pendingResult
    pendingResult = nil
    result?(FlutterError(code: errorCode, message: message, details: nil))
    isFinishing = false
  }

  private func cleanupAudio() {
    if audioEngine.isRunning {
      audioEngine.stop()
    }
    if tapInstalled {
      audioEngine.inputNode.removeTap(onBus: 0)
      tapInstalled = false
    }
    recognitionRequest?.endAudio()
    recognitionTask?.cancel()
    recognitionTask = nil
    recognitionRequest = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
