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

let SQBaseURL = URL(string: "http://10.218.0.233:8081")!
let inputPath = "/Users/Nate/Desktop/input.wav"
let outputPath = "/Users/Nate/Desktop/output.mp4"
let imagePath = "/Users/Nate/Desktop/screenshot.jpg"

class StatusMenuController: NSObject {
    @IBOutlet weak var menuOutlet: NSMenuItem!
    
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
        
        SiriQueryAPI.resetServer()
        getInput()
    }
    
    func runSiri(rawText: String) {
        if rawText == "FALSE" {
            let url = URL(fileURLWithPath: inputPath)
            player = AVPlayer(url: url)
        
            NSWorkspace.shared().launchApplication("/Applications/Siri.app")
        
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.player.play()
            
                let length = self.player.currentItem?.asset.duration
                let duration = Int(1000 * (CMTimeGetSeconds(length!)))
            
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(duration + 250), execute: {
                    self.record()
                    self.menuOutlet.title = "Listening to Siri..."
                })
            })
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                let task = Process()
                task.launchPath = "/usr/bin/say"
                task.arguments = [rawText]
                task.launch()
                task.waitUntilExit()
            })
            self.record()
            self.menuOutlet.title = "Listening to Siri..."
        }
    }


    func record() {
        checkFile(path: outputPath)
        
        let url = URL(fileURLWithPath: outputPath)
        let startTime = Date()
        
        recorder = try? AVAudioRecorder(url: url, settings: [AVFormatIDKey : kAudioFormatMPEG4AAC, AVSampleRateKey : 44100])
        recorder.prepareToRecord()
        recorder.isMeteringEnabled = true
        recorder.record()
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (Timer) in
            self.recorder.updateMeters()
            print(self.recorder.averagePower(forChannel: 0))

            if self.recorder.averagePower(forChannel: 0) < -100.0 {
                if Date().timeIntervalSince(startTime) > 3 {
                    self.recorder.stop()
                    self.levelTimer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10), execute: {
                        self.screenshot()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                            SiriQueryAPI.deliverResponse(imagePath: imagePath, audioPath: outputPath)
                            
                            self.getInput()
                        })
                    })
                }
            }
        }
    }

    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
    
    
    func checkFile(path: String) {
        let url = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            do {
                try fileManager.removeItem(at: url)
            } catch let error as NSError {
                print(error)
                menuOutlet.title = "Error"
            }
        }
    }
    
    func screenshot() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-iWao", imagePath]
        task.launch()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20), execute: {
            let task2 = Process()
            task2.launchPath = "/usr/local/bin/cliclick"
            task2.arguments = ["c:1250,100"]
            task2.launch()
        })
    }
    
    
    func getInput() {
        menuOutlet.title = "Waiting for input..."
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { (Timer) in
            self.download(url: SQBaseURL.appendingPathComponent("/nextRecording.wav"), to: URL(fileURLWithPath: inputPath), completion: { text in
                self.runSiri(rawText: text)
            })
        }
    }
    
    func download(url: URL, to localUrl: URL, completion: @escaping (String) -> ()) {
        checkFile(path: inputPath)
        
        SiriQueryAPI.recordingAvailable(completion: { newRecordingAvailable in
            if newRecordingAvailable {
                
                SiriQueryAPI.rawTextForNextQuery(completion: { rawText in
                    if let rawText = rawText {
                        completion(rawText)
                    }
                })
                
                //download the new file
                print("downloading")
                self.menuOutlet.title = "Downloading..."
                
                guard let id = SiriQueryAPI.currentTaskID else { return }
                let downloadURL = SQBaseURL.appendingPathComponent("/recordings/\(id).wav")
                
                let task = URLSession.shared.downloadTask(with: downloadURL) { (tempLocalUrl, response, error) in
                    if let tempLocalUrl = tempLocalUrl, error == nil {
                        do {
                            self.pollingTimer.invalidate()
                            
                            try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: {
                                print("running Siri")
                                self.menuOutlet.title = "Running Siri..."
                                completion("FALSE")
                            })
                            
                        } catch (let writeError) {
                            print("error writing file \(localUrl) : \(writeError)")
                            self.menuOutlet.title = "Error writing file \(localUrl) : \(writeError)"
                        }
                    }
                }
                task.resume()
                
            }
        })
        
    }
    
}





