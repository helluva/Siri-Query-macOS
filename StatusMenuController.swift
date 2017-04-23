//
//  StatusMenuController.swift
//  Siri-Query-mac
//
//  Created by Nate Thompson on 4/22/17.
//  Copyright © 2017 SiriQuery. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation

let SQBaseURL = URL(string: "http://default-environment.r34djy5xx2.us-west-2.elasticbeanstalk.com")!
let inputPath = "/Users/Nate/Desktop/input.wav"
let outputPath = "/Users/Nate/Desktop/output.mp4"

class StatusMenuController: NSObject {
    
    var player: AVPlayer!
    var recorder: AVAudioRecorder!
    var levelTimer: Timer!
    var pollingTimer: Timer!
    var startTime: Date!
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true // best for dark mode
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        getRecording()
    }
    
    @IBAction func runSiri(_ sender: Any) {
        checkFile(path: outputPath)
        
        let url = URL(fileURLWithPath: outputPath)
        let startTime = Date()
        
        recorder = try? AVAudioRecorder(url: url, settings: [AVFormatIDKey : kAudioFormatMPEG4AAC, AVSampleRateKey : 44100])
        recorder.prepareToRecord()
        recorder.isMeteringEnabled = true
        recorder.record()
        play()
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (Timer) in
            self.recorder.updateMeters()
            print(self.recorder.averagePower(forChannel: 0))

            if self.recorder.averagePower(forChannel: 0) == -120.0 {
                if Date().timeIntervalSince(startTime) > 3 {
                    self.recorder.stop()
                    self.levelTimer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(750), execute: {
                        self.screenshot()
                    })
                }
            }
        }
    }

    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
    
    func play() {
        let url = URL(fileURLWithPath: inputPath)
        player = AVPlayer(url: url)
        
        NSWorkspace.shared().launchApplication("/Applications/Siri.app")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.player.play()
        })
    }
    
    func checkFile(path: String) {
        let url = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            do {
                try fileManager.removeItem(at: url)
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    func screenshot() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-iWa", "/Users/Nate/Desktop/Screenshot.jpg"]
        task.launch()
        
        let task2 = Process()
        task2.launchPath = "/usr/local/bin/cliclick"
        task2.arguments = ["c:1250,100"]
        task2.launch()
    }
    
    
    
    func getRecording() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (Timer) in
            self.download(url: SQBaseURL.appendingPathComponent("/nextRecording.wav"), to: URL(fileURLWithPath: inputPath), completion: {
                self.runSiri(self)
            })
        }
    }
    
    func download(url: URL, to localUrl: URL, completion: @escaping () -> ()) {
        
        SiriQueryAPI.recordingAvailable(completion: { newRecordingAvailable in
            if newRecordingAvailable {
                
                //download the new file
                print("downloading")
                let task = URLSession.shared.downloadTask(with: SQBaseURL.appendingPathComponent("/nextRecording.wav")) { (tempLocalUrl, response, error) in
                    if let tempLocalUrl = tempLocalUrl, error == nil {
                        do {
                            try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: {
                                print("file downloaded")
                                completion()
                            })
                            
                        } catch (let writeError) {
                            print("error writing file \(localUrl) : \(writeError)")
                        }
                    }
                }
                task.resume()
                
            }
        })
        
    }
    
}





