//
//  ThirdPage.swift
//  iHome
//
//  Created by Sanaz Khosravi on 12/3/17.
//  Copyright © 2017 SpartanMaster. All rights reserved.
//

import UIKit
import Speech

class ThirdPage: UIViewController, SFSpeechRecognizerDelegate {
    
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    var audioPlayer = AVAudioPlayer()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    var nHum = ""
    var nTemp = ""
    let ipAddress = "192.168.0.10"
    var url: URL!
    
    @IBOutlet weak var commandValue: UILabel!
    @IBOutlet weak var resultValue: UITextView!
    @IBOutlet weak var recordingButtonOutlet: UIButton!
    @IBOutlet weak var hintButtonOuttlet: UIButton!
    
    
    
    @IBAction func recoringButttonAction(_ sender: Any) {
        
        audioPlayer = initializePlayer()!
        if audioPlayer.isPlaying{
            audioPlayer.stop()
        }
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordingButtonOutlet.isEnabled = false
            recordingButtonOutlet.setTitle("Start Recording", for: .normal)
        } else {
            
            
            startRecording()
            hintButtonOuttlet.isEnabled = false
            recordingButtonOutlet.setTitle("Stop Recording", for: .normal)
        }
    }
    
    
    @IBAction func hintButtonAction(_ sender: Any) {
        let alertSound = URL(fileURLWithPath: Bundle.main.path(forResource: "ReportCommand", ofType: "m4a")!)
        print(alertSound)
        
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try! AVAudioSession.sharedInstance().setActive(true)
        
        try! audioPlayer = AVAudioPlayer(contentsOf: alertSound)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        
    }
    
    
    //Initializing AVAudioPlayer to play audio
    private func initializePlayer() -> AVAudioPlayer? {
        guard let path = Bundle.main.path(forResource: "ReportCommand", ofType: "m4a") else {
            return nil
        }
        
        return try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
    }
    //End of function
    
    //Speech part
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordingButtonOutlet.isEnabled = true
        } else {
            recordingButtonOutlet.isEnabled = false
        }
    }
    
    //End of function
    
    
    
    
    
    
    @IBAction func secondBackButto(_ sender: Any) {
        if audioPlayer.isPlaying{
            audioPlayer.stop()
        }
        if self.audioEngine.isRunning{
            self.audioEngine.stop()
        }
        self.performSegue(withIdentifier: "secondBackButton", sender: self)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultValue.text = "No result yet."
        commandValue.text = "Your command will appear here."
        
        resultValue.textContainerInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        
        recordingButtonOutlet.isEnabled = false  //2
        
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
                self.recordingButtonOutlet.isEnabled = isButtonEnabled
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //startRecording() function which gets the voice command from user and show it in text format
    func startRecording() {
        
        
        hintButtonOuttlet.isEnabled = false
        
        
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
                
                self.commandValue.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                
                
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                self.hintButtonOuttlet.isEnabled = true
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordingButtonOutlet.isEnabled = true
                
                self.sendRequestToPie(commandToBeSent: self.commandValue.text!)
                print( self.commandValue.text!)
                
                
                
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
        
        commandValue.text = "Say your command now"
        
    }
    
    //end of function
    
    //RESTful API calls
    
    func sendRequestToPie(commandToBeSent:String){
        
        let getCommand = commandToBeSent.lowercased()
        
        if(( getCommand.range(of: "report")) != nil){
            
            self.url = URL(string: "http://"+self.ipAddress+":5000/history")!
            
            URLSession.shared.dataTask(with: self.url, completionHandler: {
                
                (data, response, error) in
                
                if(error != nil){
                    
                    print("error")
                    
                }else{
                    
                    var tempArr = [NSNumber]()
                    var humidArr = [NSNumber]()
                    do{
                        // show history data; json => array of string objects
                        let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [[String: AnyObject]]
                        
                        for data in json{
                            print(data["humidity"] ?? "0")
                            print(data["temperature"] ?? "0")
                            
                            if let hum = data["humidity"] as? NSNumber,
                                let temp = data["temperature"] as? NSNumber {
                                
                                //                                self.nTemp = temp
                                //                                self.nHum = hum
                                humidArr.append(hum)
                                tempArr.append(temp)
                                
                            }
                        }
                        
                        
                        DispatchQueue.main.sync()
                            {
                                var i: Int = 0
                                self.resultValue.text = ""
                                while(i < humidArr.count){
                                    self.resultValue.text.append("The humidity " + String(describing: i) + " is " + String(describing: humidArr[i]) + "\n")
                                    
                                    self.resultValue.text.append("The temperature " + String(describing: i) + " is " + String(describing: tempArr[i]) + "\n\n")
                                    i = i + 1
                                }
                                
                        }
                        
                        
                        
                        
                        
                    }catch let error as NSError{
                        
                        print(error)
                        
                    }
                    
                }
                
            }).resume()
            
        }else{
            self.commandValue.text = "Command not recognized"
        }
    }
    //End of function
    
    
    
    
    
}

