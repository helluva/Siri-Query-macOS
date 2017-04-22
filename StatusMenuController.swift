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
        player.play()
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
}
    
