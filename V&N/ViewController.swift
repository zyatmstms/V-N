//
//  ViewController.swift
//  V&N
//
//  Created by zyatms on 5/6/2019.
//  Copyright © 2019 com.zyatms. All rights reserved.
//

import UIKit
import CoreMotion
import CoreFoundation
import MessageUI
import Accelerate
import AVFoundation
import Charts

class ViewController: UIViewController,MFMailComposeViewControllerDelegate,AVAudioRecorderDelegate {
    
    @IBOutlet weak var chtchart: LineChartView!
    
    var recordingSession: AVAudioSession!
    private var _audiorecorder: AVAudioRecorder?
    private var audiorecoder: AVAudioRecorder!{
        if _audiorecorder == nil{
            let filename = getDirectory().appendingPathComponent(".m4a")
            let settings = [AVFormatIDKey: Int(kAudioFormatLinearPCM), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            do{
                _audiorecorder = try AVAudioRecorder(url: filename, settings: settings)
                _audiorecorder?.delegate = self
                _audiorecorder?.isMeteringEnabled = true
            }catch{
                print("failed")
            }
        }
        return _audiorecorder
    }
    /*
    private var _timer: Timer?

    private var timer: Timer! {
        if _timer == nil {
            _timer = Timer.scheduledTimer(timeInterval: 1.0/8.0, target: self, selector: #selector(updatepower), userInfo: nil, repeats: true)
        }
        return _timer
    }
    
    private var _refreshtimer: Timer?
    private var refreshtimer: Timer! {
        if _refreshtimer == nil {
            _refreshtimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateview), userInfo: nil, repeats: true)
        }
        return _timer
    }
    */
    var timer = Timer()
    var refreshtimer = Timer()
    
    @objc func updateview() -> Void {
        self.view.reloadInputViews()
        instantlabel.text = String(format: "%.1fdB(A)", label)
        Lmaxlabel.text = String(format: "%.1fdB", Lmax)
        Lminlabel.text = String(format: "%.1fdB", Lmin)
        LAeqlabel.text = String(format: "%.1fdB", LAeq)
        Timelabel.text = timeString(time: Double(count/8))
       
    }
    
    var p = [Float]()
    var mp =  [Float]()
    var dB = [Float]()
    var label = Float()
    var Lmax:Float = 0.0
    var Lmin:Float = 120.0
    var count:Float = 0.0
    var eq:Float = 0.0
    var LAeq:Float = 0.0
    var CurrentValue: Float = 0.0
    

    @IBOutlet var instantlabel: UILabel!
    @IBOutlet var LAeqlabel: UILabel!
    @IBOutlet var Timelabel: UILabel!
    @IBOutlet var Lminlabel: UILabel!
    @IBOutlet var caliLabel: UILabel!
    @IBOutlet var Lmaxlabel: UILabel!
    @IBOutlet weak var calislider: UISlider!
    
    
    @IBOutlet weak var accx: UILabel!
    @IBOutlet weak var accy: UILabel!
    @IBOutlet weak var accz: UILabel!

    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var frequency: UILabel!
    
    
    var motion = CMMotionManager()
    var currentValue: Int = 0
    var tt =  [Double]()
    var xa = [Double]()
    var ya =  [Double]()
    var za = [Double]()
    var delta_t = 0.00
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let roundedValue = slider.value.rounded()
        currentValue = Int(roundedValue)
        frequency.text = String(currentValue)
   
        CurrentValue = calislider.value
        recordingSession = AVAudioSession.sharedInstance()
        AVAudioSession.sharedInstance().requestRecordPermission { (haspermission) in
            if haspermission{
                print("permittted")
            }
        }
        audiorecoder.record()
    }
    
    @IBAction func start(_ sender: UIButton){
        timer = Timer.scheduledTimer(timeInterval: 1.0/8.0, target: self, selector: #selector(updatepower), userInfo: nil, repeats: true)
        refreshtimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateview), userInfo: nil, repeats: true)
   
        tt = []
        xa = []
        ya = []
        za = []
        delta_t = 0.00
        myAccelerometer()
        
        p = []
        mp = []
        dB = []
        Lmax = 0.0
        Lmin = 120.0
        count = 0.0
        eq = 0.0
        LAeq = 0.0
        CurrentValue = 0.0
        if audiorecoder.isRecording{
            audiorecoder.stop()
            audiorecoder.record()
            timer.fireDate = Date.distantPast
            refreshtimer.fireDate = Date.distantPast
        }else{
            audiorecoder.record()
            timer.fireDate = Date.distantPast
            refreshtimer.fireDate = Date.distantPast
        }
    }
    
    @IBAction func sliderMoved(_ slider: UISlider){
        let roundedValue = slider.value.rounded()
        currentValue = Int(roundedValue)
        frequency.text = String(currentValue)
    }
    
    @IBAction func nsliderMoved(_ slider: UISlider){
        CurrentValue = slider.value
        caliLabel.text = String(format: "%.1fdB", CurrentValue)
    }
    
    //Record Acceleration Data
    func myAccelerometer(){
        motion.accelerometerUpdateInterval = 1.00/Double(currentValue)
        motion.startAccelerometerUpdates(to: OperationQueue.current!){
            (data,error) in
            if let truedata = data {
                self.view.reloadInputViews()
                let x = truedata.acceleration.x
                let y = truedata.acceleration.y
                let z = truedata.acceleration.z
                self.xa += [x]//[Double(x).rounded(toPlaces: 8)]
                self.ya += [y]//[Double(y).rounded(toPlaces: 8)]
                self.za += [z]//[Double(z).rounded(toPlaces: 8)]
                self.tt += [self.delta_t]//[Double(self.delta_t).rounded(toPlaces: 3)]
                self.accx.text = String(format: "%.3fg", x)
                self.accy.text = String(format: "%.3fg", y)
                self.accz.text = String(format: "%.3fg", z)
                self.delta_t += self.motion.accelerometerUpdateInterval
            }
        }
    }
    
    
    @IBAction func Stop(_ sender: UIButton) {
        motion.stopAccelerometerUpdates()
        audiorecoder.pause()
        timer.invalidate()
        refreshtimer.invalidate()
    }
    /*
    //Fetch the data to .txt file and email
    @IBAction func Print(_ sender: UIButton){
        let fileName = "Accelerometerdata"
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
        print("FilePath: \(fileURL.path)")
        var record = ""
        //let vel = velocity(xa)
        // fft(vel)
        var i = 0
        repeat{
            let tString = String(format: "%.2f", tt[i])
            let xString = String(format: "%.8f", xa[i])
            let yString = String(format: "%.8f", ya[i])
            let zString = String(format: "%.8f", za[i])

            record.append(tString)
            record.append("     ")
            record.append(xString)
            record.append("     ")
            record.append(yString)
            record.append("     ")
            record.append(zString)
            record.append("     ")

            record.append("\n")
            i += 1
        }while i < tt.count
        
        do {
            // Write to the file
            try record.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
        }
        
        if MFMailComposeViewController.canSendMail(){
            let subject = "Accelerometer data"
            let messageBody = "Data recoded"
            let toRecipents = ["14110723d@connect.polyu.hk"]
            let mailcomposer = MFMailComposeViewController()
            
            mailcomposer.mailComposeDelegate = self
            mailcomposer.setSubject(subject)
            mailcomposer.setMessageBody(messageBody, isHTML: false)
            mailcomposer.setToRecipients(toRecipents)
            if let filedata = NSData(contentsOf: fileURL){
                mailcomposer.addAttachmentData(filedata as Data, mimeType: "txt", fileName: fileName.appending(".txt"))
                present(mailcomposer,animated: true,completion: nil)
            }
        }
    }
    */
    @IBAction func Emaildata(_ sender: UIButton){
        let fileName2 = "Noisemeterdata"
        let DocumentDirURL2 = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL2 = DocumentDirURL2.appendingPathComponent(fileName2).appendingPathExtension("txt")
        print("FilePath: \(fileURL2.path)")
        var record2 = ""
        var ii = 1
        repeat{
            let zString = String(format: "%.8f", dB[ii])
            record2.append(zString)
            record2.append("\n")
                ii += 8
        }while ii < p.count
    //加了acceleration
        let fileName = "Accelerometerdata"
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
        print("FilePath: \(fileURL.path)")
        var record = ""
        //let vel = velocity(xa)
        // fft(vel)
        var i = 0
        repeat{
            let tString = String(format: "%.2f", tt[i])
            let xString = String(format: "%.8f", xa[i])
            let yString = String(format: "%.8f", ya[i])
            let zString = String(format: "%.8f", za[i])
            
            record.append(tString)
            record.append("     ")
            record.append(xString)
            record.append("     ")
            record.append(yString)
            record.append("     ")
            record.append(zString)
            record.append("     ")
            
            record.append("\n")
            i += 1
        }while i < tt.count
        
        do {
    // Write to the file
            try record2.write(to: fileURL2, atomically: true, encoding: String.Encoding.utf8)
            } catch let error as NSError {
                print("Failed writing to URL: \(fileURL2), Error: " + error.localizedDescription)
        }
    //加了acceleration
        do {
            // Write to the file
            try record.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
        }

        
        
        if MFMailComposeViewController.canSendMail(){
            let subject = "Measured data"
            let messageBody = "Data recoded"
            let toRecipents = ["14110723d@connect.polyu.hk"]
            let mailcomposer = MFMailComposeViewController()
    
            mailcomposer.mailComposeDelegate = self
            mailcomposer.setSubject(subject)
            mailcomposer.setMessageBody(messageBody, isHTML: false)
            mailcomposer.setToRecipients(toRecipents)
            if let filedata = NSData(contentsOf: fileURL){
                mailcomposer.addAttachmentData(filedata as Data, mimeType: "txt", fileName: fileName.appending(".txt"))
            }
            if let filedata2 = NSData(contentsOf: fileURL2){
                mailcomposer.addAttachmentData(filedata2 as Data, mimeType: "txt", fileName: fileName2.appending(".txt"))
                present(mailcomposer,animated: true,completion: nil)
            }
        }
}
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
    func getDirectory() ->URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
    
    
    
    @objc func updatepower() -> Void {
        audiorecoder.updateMeters()
        //self.view.reloadInputViews()
        let power = audiorecoder.averagePower(forChannel: 0)
        let maxpower = audiorecoder.peakPower(forChannel: 0)
        self.count += 1.0;
        let Tm = count/8.0;
        var dB:Float = 0.0;
        var level: Float ;
        let minDecibels:Float = -160.0;
        
        if (power < minDecibels)
        {
            level = 0.0;
        }
        else if (power >= 0.0)
        {
            level = 1.0;
        }
        else
        {
            let root:Float            = 5.0; //modified level from 2.0 to 5.0 is neast to real test
            let minAmp = powf(10.0, 0.05 * minDecibels);
            let inverseAmpRange = 1.0 / (1.0 - minAmp);
            let amp             = powf(10.0, 0.05 * power);
            let adjAmp          = (amp - minAmp) * inverseAmpRange;
            
            level = powf(adjAmp, 1.0 / root);
        }
        dB = level * 110;
        dB = dB + CurrentValue;
        
        print(power, maxpower,dB);
        //powerlabel.text = String(format: "%.1fdB", dB)
        self.p += [power]//[Double(x).rounded(toPlaces: 8)]
        self.mp += [maxpower]//[Double(y).rounded(toPlaces: 8)]
        self.dB += [dB]
        label = dB
        if (dB > Lmax){
            Lmax = dB ;
        }
        if (dB < Lmin){
            Lmin = dB ;
        }
        self.eq += powf(10.0,dB/10.0)/8.0;
        LAeq = 10*log10(eq/Tm);
        
        
         var lineChartEntry1  = [ChartDataEntry]() //this is the Array that will eventually be displayed on the graph.
         var lineChartEntry2  = [ChartDataEntry]()
         var lineChartEntry3  = [ChartDataEntry]()
         
         //here is the for loop
         if xa.count < 500 {
         for i in 0..<xa.count {
         
         let value1 = ChartDataEntry(x: tt[i], y: xa[i]) // here we set the X and Y status in a data chart entry
         
         lineChartEntry1.append(value1)
         
         let value2 = ChartDataEntry(x: tt[i], y: ya[i]) // here we set the X and Y status in a data chart entry
         
         lineChartEntry2.append(value2)
         
         let value3 = ChartDataEntry(x: tt[i], y: za[i]) // here we set the X and Y status in a data chart entry
         
         lineChartEntry3.append(value3)
         
         }
         }else{
         let a = xa.count-500+1
         for i in a..<xa.count {
         
         let value1 = ChartDataEntry(x: tt[i], y: xa[i]) // here we set the X and Y status in a data chart entry
         
         lineChartEntry1.append(value1)
         
         let value2 = ChartDataEntry(x: tt[i], y: ya[i]) // here we set the X and Y status in a data chart entry
         
         lineChartEntry2.append(value2)
         
         let value3 = ChartDataEntry(x: tt[i], y: za[i]) // here we set the X and Y status in a data chart entry
         
         lineChartEntry3.append(value3)
         
         }
         }
         
         let line1 = LineChartDataSet(entries: lineChartEntry1, label: "ACCx") //Here we convert lineChartEntry to a LineChartDataSet
         
         line1.colors = [NSUIColor.blue] //Sets the colour to blue
         line1.drawCirclesEnabled = false
         line1.drawValuesEnabled = false
         
         let line2 = LineChartDataSet(entries: lineChartEntry2, label: "ACCy") //Here we convert lineChartEntry to a LineChartDataSet
         
         line2.colors = [NSUIColor.red] //Sets the colour to blue
         line2.drawCirclesEnabled = false
         line2.drawValuesEnabled = false
         
         let line3 = LineChartDataSet(entries: lineChartEntry3, label: "ACCz") //Here we convert lineChartEntry to a LineChartDataSet
         
         line3.colors = [NSUIColor.yellow] //Sets the colour to blue
         line3.drawCirclesEnabled = false
         line3.drawValuesEnabled = false
         
         let data = LineChartData(dataSets: [line1, line2, line3])
         /*
         let data = LineChartData() //This is the object that will be added to the chart
         
         data.addDataSet(line1) //Adds the line to the dataSet
         */
         
         chtchart.data = data //finally - it adds the chart data to the chart and causes an update*/
        
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }

}
extension Double {
    // Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double{
        let divisor = pow(10.00, Double(places))
        return (self*divisor).rounded()/divisor
    }
}



