//
//  SecondViewController.swift
//  iHome
//
//  Created by Sanaz Khosravi on 12/4/17.
//  Copyright © 2017 SpartanMaster. All rights reserved.
//

import UIKit
import Speech

class SecondViewController: UIViewController, SFSpeechRecognizerDelegate  {
    
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    var audioPlayer = AVAudioPlayer()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    var nHum = ""
    var nTemp = ""
    var ipAddress = "192.168.0.10"
    var url: URL!
    
    
    @IBOutlet weak var commandValue: UILabel!
    
    @IBOutlet weak var resultValue: UITextView!
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var startRecordingButton: UIButton!
    
    @IBAction func startRecordingButtonTapped(_ sender: Any) {
        
        
        audioPlayer = initializePlayer()!
        if audioPlayer.isPlaying{
            audioPlayer.stop()
        }
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            startRecordingButton.isEnabled = false
            startRecordingButton.setTitle("Start Recording", for: .normal)
        } else {
            
            
            startRecording()
            hinttButton.isEnabled = false
            startRecordingButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    
    @IBOutlet weak var backButton: UIButton!
    
    
    @IBOutlet weak var hinttButton: UIButton!
    
    @IBAction func backButtontapped(_ sender: Any) {
        if audioPlayer.isPlaying{
           audioPlayer.stop()
        }
        if self.audioEngine.isRunning{
            self.audioEngine.stop()
        }
        self.performSegue(withIdentifier: "firstBackButton", sender: self)
    }
    
    @IBAction func hintButtontapped(_ sender: Any) {
        
        let alertSound = URL(fileURLWithPath: Bundle.main.path(forResource: "SecondPageCommand", ofType: "m4a")!)
        print(alertSound)
        
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try! AVAudioSession.sharedInstance().setActive(true)
        
        try! audioPlayer = AVAudioPlayer(contentsOf: alertSound)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
    }
    
    
    //Initializing AVAudioPlayer to play audio
    private func initializePlayer() -> AVAudioPlayer? {
        guard let path = Bundle.main.path(forResource: "SecondPageCommand", ofType: "m4a") else {
            return nil
        }
        
        return try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
    }
    //End of function
    
    
    
    //Speech part
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            startRecordingButton.isEnabled = true
        } else {
            startRecordingButton.isEnabled = false
        }
    }
    
    //End of function
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        resultValue.text = "No result yet."
        commandValue.text = "Your command will appear here."
        
        resultValue.textContainerInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        
        startRecordingButton.isEnabled = false  //2
        
        speechRecognizer?.delegate = self  //3
        
        self.imageView.image = UIImage(named: "background.png")!
        
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
                self.startRecordingButton.isEnabled = isButtonEnabled
            }
        }

        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startRecording() {
        
        
        hinttButton.isEnabled = false
        
        
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
                self.hinttButton.isEnabled = true
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.startRecordingButton.isEnabled = true
                
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
        
        
        
        if(getCommand == "on" || getCommand == "off"){
            
            self.url = URL(string: "http://"+self.ipAddress+":5000/red?output="+getCommand)!
            
            URLSession.shared.dataTask(with: self.url, completionHandler: {
                
                (data, response, error) in
                
                if(error != nil){
                    
                    print("error")
                    
                }else{
                    
                    do{
                        
                        let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                        
                        
                        
                        DispatchQueue.main.sync()
                            
                            {
                                
                                self.resultValue.text = "The light is now " + getCommand
                                
                                if(getCommand == "off"){
                                    
                                    self.imageView.image = UIImage(named: "led-off-hi.png")!
                                    
                                }else{
                                    
                                    
                                    
                                    self.imageView.image = UIImage(named: "red-led-off-hi.png")!
                                    
                                    
                                    
                                }
                                
                        }
                        
                        
                        
                        
                        
                    }catch let error as NSError{
                        
                        print(error)
                        
                        self.resultValue.text = error.localizedDescription
                        
                    }
                    
                }
                
            }).resume()
            
        }else if(getCommand == "humidity" || getCommand == "temperature"){
            
            self.url = URL(string: "http://"+self.ipAddress+":5000/temphumid")!
            
            URLSession.shared.dataTask(with: self.url, completionHandler: {
                
                (data, response, error) in
                
                if(error != nil){
                    
                    print("error")
                    
                }else{
                    
                    do{
                        
                        let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]

                        
                        if let result = json["result"] as? String,
                            
                            let hum = json["humidity"] as? String,
                            
                            let temp = json["temp"] as? String {
                            
                            NSLog(result)
                            
                            self.nTemp = temp
                            
                            self.nHum = hum

                        }
                        
                        DispatchQueue.main.sync()
                            
                            {
                                

                                self.resultValue.text = "The humidity is " + self.nHum + "\n"
                                
                                self.resultValue.text.append("The temperature is " + self.nTemp)
                                
                        }
                        
                        
                        
                        
                        
                    }catch let error as NSError{
                        
                        print(error)
                        
                    }
                    
                }
                
            }).resume()
            
        }else if(( getCommand.range(of: "blue")) != nil){
        
            self.url = URL(string: "http://"+self.ipAddress+":5000/rgb?r=0&g=0&b=255")!
            
            URLSession.shared.dataTask(with: self.url, completionHandler: {
                
                (data, response, error) in
                
                if(error != nil){
                    
                    print("error")
                    
                }else{
                    
                    do{
                        
                        let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                        
                        
                        
                        DispatchQueue.main.sync()
                            
                            {
                                self.resultValue.text = "The RGB light color is changed to blue "
                                
                                self.imageView.image = UIImage(named: "blue.png")!
                                
                                
                                
                        }
                        
                    }catch let error as NSError{
                        
                        print(error)
                        
                    }
                    
                }
                
            }).resume()
            
            
            
        }else if(( getCommand.range(of: "yellow")) != nil){
            
            self.url = URL(string: "http://"+self.ipAddress+":5000/rgb?r=255&g=255&b=0")!
            
            URLSession.shared.dataTask(with: self.url, completionHandler: {
                
                (data, response, error) in
                
                if(error != nil){
                    
                    print("error")
                    
                }else{
                    
                    do{
                        
                        let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                        
                        
                        
                        DispatchQueue.main.sync()
                            
                            {
                                
                                
                                
                                
                                
                                self.resultValue.text = "The RGB light color is changed to yellow "
                                
                                self.imageView.image = UIImage(named: "yellow.png")!
                                
                                
                                
                        }
                        
                        
                        
                        
                        
                    }catch let error as NSError{
                        
                        print(error)
                        
                    }
                    
                }
                
            }).resume()
            
            
            
        }else if(( getCommand.range(of: "red")) != nil){
            
            self.url = URL(string: "http://"+self.ipAddress+":5000/rgb?r=255&g=51&b=0")!
            
            URLSession.shared.dataTask(with: self.url, completionHandler: {
                
                (data, response, error) in
                
                if(error != nil){
                    
                    print("error")
                    
                }else{
                    
                    do{
                        
                        let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                        
                        
                        
                        DispatchQueue.main.sync()
                            
                            {
                                
                                
                                
                                
                                
                                self.resultValue.text = "The RGB light color is changed to red "
                                
                                self.imageView.image = UIImage(named: "red.png")!
                                
                                
                                
                        }
                        
                        
                        
                        
                        
                    }catch let error as NSError{
                        
                        print(error)
                        
                    }
                    
                }
                
            }).resume()
            
            
            
        }else if(( getCommand.range(of: "green")) != nil){
            
            self.url = URL(string: "http://"+self.ipAddress+":5000/rgb?r=0&g=153&b=51")!
            
            URLSession.shared.dataTask(with: self.url, completionHandler: {
                
                (data, response, error) in
                
                if(error != nil){
                    
                    print("error")
                    
                }else{
                    
                    do{
                        
                        let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                        
                        
                        
                        DispatchQueue.main.sync()
                            
                            {
                                
                                
                                
                                
                                
                                self.resultValue.text = "The RGB light color is changed to green "
                                
                                self.imageView.image = UIImage(named: "green.png")!
                                
                                
                                
                        }
                        
                        
                        
                        
                        
                    }catch let error as NSError{
                        
                        print(error)
                        
                    }
                    
                }
                
            }).resume()
            
            
            
        } else{
            self.commandValue.text = "Command not recognized"
        }
        

        
    }
    //End of function
    
    
    
    

}
