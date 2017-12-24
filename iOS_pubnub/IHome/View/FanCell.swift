//
//  FanCell.swift
//  IHome
//
//  Created by Maryam Jafari on 12/18/17.
//  Copyright © 2017 Maryam Jafari. All rights reserved.
//

import UIKit
import Speech
import PubNub // Stephen

class FanCell: UITableViewCell, SFSpeechRecognizerDelegate, PNObjectEventListener  {
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    var audioPlayer = AVAudioPlayer()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    
    @IBOutlet weak var name: UILabel!
    var status : String! = "OFF"
    
    // <++++++++ Stephen
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate // Stephen
    struct myPubNubMessage: Codable {
        let Name: String
        let Types: String // "Light", "AC", "Fan", "TV", or "Door"
        let Action: String // "ON" or "OFF"
    }
    // ++++++> Stephen
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = 5.0
        
        // <++++++++ Stephen
        appDelegate.client.addListener(self)
        appDelegate.client.subscribeToChannels(["my_channel"], withPresence: true)
        // ++++++++> Stephen
    }
    
    //<++++++++ Stephen
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        print("Received message: \(message.data.message) on channel \(message.data.channel) " +
            "at \(message.data.timetoken)")
        
        let array = (message.data.message as! NSArray).mutableCopy() as! NSMutableArray
        print(array[0])
        
        let receivedMessage = array[0] as! [NSString : NSString]
        let _name :NSString = receivedMessage["Name"]!
        let _types :NSString = receivedMessage["Types"]!
        let _action :NSString = receivedMessage["Action"]!
        print(_name)
        print(_types)
        print(_action)
        
        if (_types == "Fan" && _name as String == name.text!) {
            self.status = _action as String!;
            if status == "ON" {
                DispatchQueue.main.async() {
                     self.onAndOff.setBackgroundImage(UIImage(named: "icons8-shit-hits-fan-40"), for: UIControlState.normal)
                
                }
            } else {
                DispatchQueue.main.async() {
                       self.onAndOff.setBackgroundImage(UIImage(named : "icons8-fan-40"), for: UIControlState.normal)
                }
            }
        }
        print(self.status)
    }
    // ++++++++> Stephen
    
    @IBOutlet weak var onAndOff: UIButton!
    
    @IBAction func OnOff(_ sender: Any) {
        if status == "ON"{
            //onAndOff.setBackgroundImage(UIImage(named : "icons8-restart-40"), for: UIControlState.normal)
            //status = "OFF"
            //<++++++++ Stephen
            let originalObjects = [myPubNubMessage(Name: name.text!, Types: "Fan", Action: "OFF")]
            let encoder = JSONEncoder()
            let data = try! encoder.encode(originalObjects)
            print(data)
            print(String(data: data, encoding: .utf8)!)
            appDelegate.client.publish(String(data: data, encoding: .utf8)!, toChannel: "my_channel", compressed: false, withCompletion: nil)
            // ++++++++> Stephen
        }
        else{
            //onAndOff.setBackgroundImage(UIImage(named: "icons8-shutdown-40"), for: UIControlState.normal)
            //status = "ON"
            //<++++++++ Stephen
            let originalObjects = [myPubNubMessage(Name: name.text!, Types: "Fan", Action: "ON")]
            let encoder = JSONEncoder()
            let data = try! encoder.encode(originalObjects)
            print(data)
            print(String(data: data, encoding: .utf8)!)
            appDelegate.client.publish(String(data: data, encoding: .utf8)!, toChannel: "my_channel", compressed: false, withCompletion: nil)
            // ++++++++> Stephen
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
                
                self.sendRequestToPubNub(commandToBeSent: (result?.bestTranscription.formattedString)!)
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
    
    // <++++++ Stephen
    func sendRequestToPubNub(commandToBeSent:String) {
        let getCommand = commandToBeSent.lowercased()
        var showString : String = "Cannot Recognize!"
        if (getCommand == "on" || getCommand == "open") {
            let originalObjects = [myPubNubMessage(Name: name.text!, Types: "Fan", Action: "ON")]
            let encoder = JSONEncoder()
            let data = try! encoder.encode(originalObjects)
            print(data)
            print(String(data: data, encoding: .utf8)!)
            appDelegate.client.publish(String(data: data, encoding: .utf8)!, toChannel: "my_channel", compressed: false, withCompletion: nil)
            showString = getCommand
        } else if (getCommand == "off" || getCommand == "close") {
            let originalObjects = [myPubNubMessage(Name: name.text!, Types: "Fan", Action: "OFF")]
            let encoder = JSONEncoder()
            let data = try! encoder.encode(originalObjects)
            print(data)
            print(String(data: data, encoding: .utf8)!)
            appDelegate.client.publish(String(data: data, encoding: .utf8)!, toChannel: "my_channel", compressed: false, withCompletion: nil)
            showString = getCommand
        } else {
            showString = "Cannot Recognize!"
        }
        print(showString)
        let alert = UIAlertController(title: "Voice Recognition", message: showString, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            print(showString)
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    // ++++++++> Stephen
    
    //end of function
    
    func configureCell(lableName : String, newStatus : String){
        
        name.text = lableName.capitalized
        status = newStatus
        
        if status == "ON"{
            onAndOff.setBackgroundImage(UIImage(named: "icons8-shit-hits-fan-40"), for: UIControlState.normal)
            //status = "OFF"
            
        }
        else{
             onAndOff.setBackgroundImage(UIImage(named : "icons8-fan-40"), for: UIControlState.normal)
           
            //status = "ON"
        }
        
    }
    
}

