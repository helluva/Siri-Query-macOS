//
//  NSImage+Crop.swift
//  Siri-Query-mac
//
//  Created by Nate Thompson on 4/23/17.
//  Copyright © 2017 SiriQuery. All rights reserved.
//

import AppKit

extension NSImage {
    
    //self.size is inaccurate for some image representations
    var actualPixelSize: CGSize {
        guard let tiffData = self.tiffRepresentation else { return self.size }
        guard let rep = NSBitmapImageRep(data: tiffData) else { return self.size }
        return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    }
    
    //custom drawing because lockFocus() depends on device resolution
    static func newImage(ofSize size: CGSize, render: (CGContext) -> ()) -> NSImage {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                      pixelsWide: Int(size.width),
                                      pixelsHigh: Int(size.height),
                                      bitsPerSample: 8,
                                      samplesPerPixel: 4,
                                      hasAlpha: true,
                                      isPlanar: false,
                                      colorSpaceName: NSDeviceRGBColorSpace,
                                      bytesPerRow: 0,
                                      bitsPerPixel: 0)!
        
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: bitmap)!.cgContext
        render(context)
        NSGraphicsContext.restoreGraphicsState()
        
        let image = NSImage(size: size)
        image.addRepresentation(bitmap)
        return image
    }
    
    var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: self.size)
        return NSImage.cgImage(self)(forProposedRect: &rect, context: nil, hints: nil)
    }
}
