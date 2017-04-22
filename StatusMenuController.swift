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
    
    var player: AVPlayer!
    var recorder: AVAudioRecorder!
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true // best for dark mode
        statusItem.image = icon
        statusItem.menu = statusMenu
    }
    
    @IBAction func playClicked(_ sender: NSMenuItem) {
        let url = URL(fileURLWithPath: "/Users/Nate/Desktop/siriTest.mp3")
        player = AVPlayer(url: url)
        
        NSWorkspace.shared().launchApplication("/Applications/Siri.app")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.player.play()
        })
    }
    
    @IBAction func recordClicked(_ sender: NSMenuItem) {
        let url = URL(fileURLWithPath: "/Users/Nate/Desktop/nort.mp4")
        recorder = try? AVAudioRecorder(url: url, settings: [AVFormatIDKey : kAudioFormatMPEG4AAC, AVSampleRateKey : 44100])
        recorder.prepareToRecord()
        recorder.record()
    }
    
    @IBAction func stopClicked(_ sender: NSMenuItem) {
        recorder.stop()
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
}
    
