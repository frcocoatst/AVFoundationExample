//
//:  ViewController.swift
//  AVFoundationExample
//
//  from: https://www.invasivecode.com/weblog/AVFoundation-Swift-capture-video/
//

import Cocoa
import AVFoundation
import CoreImage

/* Filters to be applied
let CMYKHalftone = "CMYK Halftone"
let CMYKHalftoneFilter = CIFilter(name: "CICMYKHalftone", withInputParameters: ["inputWidth" : 20, "inputSharpness": 1])

let ComicEffect = "Comic Effect"
let ComicEffectFilter = CIFilter(name: "CIComicEffect")

let Crystallize = "Crystallize"
let CrystallizeFilter = CIFilter(name: "CICrystallize", withInputParameters: ["inputRadius" : 30])

let Edges = "Edges"
let EdgesEffectFilter = CIFilter(name: "CIEdges", withInputParameters: ["inputIntensity" : 10])

let HexagonalPixellate = "Hex Pixellate"
let HexagonalPixellateFilter = CIFilter(name: "CIHexagonalPixellate", withInputParameters: ["inputScale" : 40])

let Invert = "Invert"
let InvertFilter = CIFilter(name: "CIColorInvert")

let Pointillize = "Pointillize"
let PointillizeFilter = CIFilter(name: "CIPointillize", withInputParameters: ["inputRadius" : 30])

let LineOverlay = "Line Overlay"
let LineOverlayFilter = CIFilter(name: "CILineOverlay")

let Posterize = "Posterize"
let PosterizeFilter = CIFilter(name: "CIColorPosterize", withInputParameters: ["inputLevels" : 5])

let Filters = [
    CMYKHalftone: CMYKHalftoneFilter,
    ComicEffect: ComicEffectFilter,
    Crystallize: CrystallizeFilter,
    Edges: EdgesEffectFilter,
    HexagonalPixellate: HexagonalPixellateFilter,
    Invert: InvertFilter,
    Pointillize: PointillizeFilter,
    LineOverlay: LineOverlayFilter,
    Posterize: PosterizeFilter
]

let FilterNames = [String](Filters.keys).sorted()
*/

extension CIImage {
    func toNSImage() -> NSImage {
        let rep = NSCIImageRep(ciImage: self)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        
        return nsImage
    }
}

extension NSImage {
    func toCIImage() -> CIImage? {
        let resultImage = CIImage()
        let tiffData = self.tiffRepresentation!
        if let bitmapImageRep = NSBitmapImageRep(data: tiffData), let resultImage = CIImage(bitmapImageRep: bitmapImageRep) {
            return resultImage
        }
        return resultImage
    }
}

// MARK: - Conversion Methods CGImage <--> NSImage

extension NSImage {
     // from http://qiita.com/HaNoHito/items/2fe95aba853f9cedcd3e
    func toCGImage() -> CGImage {
        var imageRect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let image = cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
            else {
                abort()
        }
        return image
    }
}

extension CGImage {
     // from http://qiita.com/HaNoHito/items/2fe95aba853f9cedcd3e
    func toNSImage() -> NSImage {
        let width = self.width
        let height = self.height
        let size = CGSize(width: width, height: height)
        return NSImage(cgImage: self, size: size)
    }
}


class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var preView: NSView!
    
    @IBOutlet weak var camView: NSImageView!
    @IBOutlet weak var stillImageView: NSImageView!

    //var stillImageOutput : AVCaptureStillImageOutput!
    let stillImageOutput = AVCaptureStillImageOutput()
    
    @IBAction func takePicture(_ sender: Any) {
        
        print("Capturing image")
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        if let videoConnection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo){
            print("-->")
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: {
                (sampleBuffer, error) in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                // ???
                let image = NSImage(data: imageData!)
                /*
                let dataProvider = CGDataProvider(data: imageData! as CFData)
                let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                
                // let image = NSImage(initWithCGImage:cgImageRef)
                let image = cgImageRef!.toNSImage()
                */
                print("image")
                self.stillImageView.image  = image
                // self.stillImageView.needsDisplay = true
                DispatchQueue.main.async {
                    
                    // self.camView.setNeedsDisplay
                    self.stillImageView.needsDisplay = true
                    
                }
                
                //Show the captured image to
                // self.view.addSubview(cgImageRef.)
                
                //Save the captured preview to image
                // UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageView = NSImageView()
        // imageView.frame = self.view.frame    // full frame
        imageView.frame = camView.frame
        self.view.addSubview(imageView)
        self.camView = imageView
        
        setupCameraSession()                    // setup camera session
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        preView.wantsLayer = true
        preView.layer?.borderWidth = 2.0
        preView.layer?.borderColor = NSColor.red.cgColor
        preView.layer?.cornerRadius = 8.0
        preView.layer?.masksToBounds = true
        preView.layer?.addSublayer(previewLayer) // <-- add preview layer
        
        cameraSession.startRunning()
    }
    
/*
    func fromCIImage(_ ciImage: CIImage) -> NSImage
    {
        let imageRep = NSCIImageRep(ciImage: ciImage)
        let result = NSImage(size: imageRep.size)
        result.addRepresentation(imageRep)
        return result;
    }
*/
    
    lazy var cameraSession: AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = AVCaptureSessionPresetHigh
        return s
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
        preview?.bounds = CGRect(x: 0, y: 0, width: self.preView.bounds.width, height: self.preView.bounds.height)
        preview?.position = CGPoint(x: self.preView.bounds.midX, y: self.preView.bounds.midY)
        preview?.videoGravity = AVLayerVideoGravityResize
        return preview!
    }()

    func setupCameraSession() {
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) as AVCaptureDevice
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            cameraSession.beginConfiguration()
            
            if (cameraSession.canAddInput(deviceInput) == true) {
                cameraSession.addInput(deviceInput)
            }
            
            /*
             AVCaptureStillImageOutput  -   capture output for recording still images.
             AVCaptureVideoDataOutput   -   capture output that records video and provides access   to video frames for processing.
             AVCaptureMetadataOutput    -   enables detection of faces and QR codes
             */
            
            // stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            if cameraSession.canAddOutput(stillImageOutput) {
                cameraSession.addOutput(stillImageOutput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (cameraSession.canAddOutput(dataOutput) == true) {
                cameraSession.addOutput(dataOutput)
            }
            
            cameraSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "com.invasivecode.videoQueue")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        // Here you collect each frame and process it
        // print("captured \(sampleBuffer)")
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)

        // let filter = CIFilter(name: "CIComicEffect")
        // let filter = CIFilter(name: "CISepiaTone")
        // let filter = CIFilter(name: "CIColorInvert")
        // let filter = CIFilter(name: "CILineOverlay")
        // let filter = CIFilter(name: "CIPhotoEffectNoir")
        // let filter = CIFilter(name: "CICMYKHalftone")
        // let filter = CIFilter(name: "CIMedianFilter")
        // let filter = CIFilter(name: "CICrystallize", withInputParameters: ["inputRadius" : 30])
        // let filter = CIFilter(name: "CIEdges", withInputParameters: ["inputIntensity" : 10])
        // let filter = CIFilter(name: "CIColorPosterize", withInputParameters: ["inputLevels" : 5])
        // let filter = CIFilter(name: "CIHexagonalPixellate", withInputParameters: ["inputScale" : 50])
        // let filter = CIFilter(name: "CIExposureAdjust", withInputParameters: ["inputEV": -2.5])
        // let filter = CIFilter(name: "CIGaussianBlur", withInputParameters: ["inputRadius": 8])
        
        // let filter = CIFilter(name: "CIGloom", withInputParameters: ["inputRadius": 10.0, "inputIntensity":1.5])
        
        let filter = CIFilter(name: "CISepiaTone")

        filter!.setValue(cameraImage, forKey: kCIInputImageKey)
        
        let filteredImage = filter!.value(forKey: kCIOutputImageKey) as! CIImage
        
        // let shownImage = self.fromCIImage(filteredImage)
        let shownImage = filteredImage.toNSImage()
        //print("filteredImage \(shownImage)")
        self.camView.image  = shownImage
        
        DispatchQueue.main.async {
            
            // self.camView.setNeedsDisplay
            self.camView.needsDisplay = true
            
        }

    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        // Here you can count how many frames are dopped
        print("frames are dopped")

    }


}

