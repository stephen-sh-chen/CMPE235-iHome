//
//  FridgeCell.swift
//  IHome
//
//  Created by Maryam Jafari on 12/18/17.
//  Copyright © 2017 Maryam Jafari. All rights reserved.
//

import UIKit
import Speech
class FridgeCell: UITableViewCell, SFSpeechRecognizerDelegate  {
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    var audioPlayer = AVAudioPlayer()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    @IBOutlet weak var name: UILabel!
    var status : String! = "OFF"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        layer.cornerRadius = 5.0
        
    }
    
    @IBOutlet weak var onAndOff: UIButton!
    
    @IBAction func OnOff(_ sender: Any) {
        
        
        
        if status == "ON"{
            onAndOff.setBackgroundImage(UIImage(named : "icons8-checkmark-40"), for: UIControlState.normal)
            status = "OFF"
            
        }
        else{
            onAndOff.setBackgroundImage(UIImage(named: "icons8-expired-40"), for: UIControlState.normal)
            status = "ON"
        }
        
    }
    
    
    @IBOutlet weak var record: UIButton!
    
    @IBAction func recordVoice(_ sender: Any) {
        record.isEnabled = false  //2
        
        speechRecognizer?.delegate = self  //3
        
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.record.isEnabled = isButtonEnabled
            }
        }
        
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            record.isEnabled = false
        } else {
            startRecording()
        }
        
    }
    
    
    //Speech part
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            record.isEnabled = true
        } else {
            record.isEnabled = false
        }
    }
    
    //End of function
    
    func startRecording() {
        
        
        
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                isFinal = (result?.isFinal)!
                
                
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.record.isEnabled = true
                
                
                print(result?.bestTranscription.formattedString)
                
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        
    }
    
    func configureCell(lableName : String, newStatus : String){
        
        name.text = lableName.capitalized
        status = newStatus
        
        if status == "ON"{
            onAndOff.setBackgroundImage(UIImage(named : "icons8-checkmark-40"), for: UIControlState.normal)
            status = "OFF"
            
        }
        else{
            onAndOff.setBackgroundImage(UIImage(named: "icons8-expired-40"), for: UIControlState.normal)
            status = "ON"
        }
        
    }
    
}

