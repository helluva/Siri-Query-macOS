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

class StatusMenuController: NSObject {
    
    let savePath = "/Users/Nate/Desktop/Recording.mp4"
    var player: AVPlayer!
    var recorder: AVAudioRecorder!
    var timer: Timer!
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true // best for dark mode
        statusItem.image = icon
        statusItem.menu = statusMenu
    }
    
    @IBAction func recordClicked(_ sender: NSMenuItem) {
        checkFile()
        
        let url = URL(fileURLWithPath: savePath)
        let startTime = Date()
        recorder = try? AVAudioRecorder(url: url, settings: [AVFormatIDKey : kAudioFormatMPEG4AAC, AVSampleRateKey : 44100])
        recorder.prepareToRecord()
        recorder.isMeteringEnabled = true
        recorder.record()
        play()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (Timer) in
            self.recorder.updateMeters()
            print(self.recorder.averagePower(forChannel: 0))
            if self.recorder.averagePower(forChannel: 0) == -120.0 {
                if Date().timeIntervalSince(startTime) > 3 {
                    self.recorder.stop()
                    self.timer.invalidate()
                }
            }
        }
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
    
    func play() {
        let url = URL(fileURLWithPath: "/Users/Nate/Desktop/siriTest.mp3")
        player = AVPlayer(url: url)
        
        NSWorkspace.shared().launchApplication("/Applications/Siri.app")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.player.play()
        })
    }
    
    func checkFile() {
        let url = URL(fileURLWithPath: savePath)
        let filePath = url.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            do {
                try fileManager.removeItem(at: url)
            } catch let error as NSError {
                print(error)
            }
        }
    }
}
    
