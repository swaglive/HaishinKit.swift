//
//  CustomBufferView.swift
//  HaishinKit iOS
//
//  Created by 立宣于 on 2022/6/20.
//  Copyright © 2022 Shogo Endo. All rights reserved.
//

import AVFoundation
import UIKit

open class CustomBufferView: UIView, NetStreamRenderer {
    deinit {
        attachStream(nil)
    }

    override open class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }

    override open var layer: AVSampleBufferDisplayLayer {
        super.layer as! AVSampleBufferDisplayLayer
    }

    public var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            layer.videoGravity = videoGravity
        }
    }

    var position: AVCaptureDevice.Position = .front

    var orientation: AVCaptureVideoOrientation = .portrait

    var currentSampleBuffer: CMSampleBuffer?

    var videoFormatDescription: CMVideoFormatDescription? {
        currentStream?.mixer.videoIO.formatDescription
    }

    private weak var currentStream: NetStream? {
        didSet {
            oldValue?.mixer.videoIO.renderer = nil
        }
    }

    func enqueue(_ sampleBuffer: CMSampleBuffer?) {
        guard let buffer = sampleBuffer else {
            return
        }
        DispatchQueue.main.async {
            self.enqueue(buffer)
        }
    }

    func enqueue(_ sampleBuffer: CMSampleBuffer) {
        if layer.status == .failed {
            layer.flush()
        }
        if layer.isReadyForMoreMediaData {
            layer.enqueue(sampleBuffer)
        }
    }

    open func attachStream(_ stream: NetStream?) {
        guard let stream = stream else {
            currentStream = nil
            return
        }

        stream.lockQueue.async {
            stream.mixer.videoIO.renderer = self
            self.currentStream = stream
            stream.mixer.startRunning()
        }
    }
}
