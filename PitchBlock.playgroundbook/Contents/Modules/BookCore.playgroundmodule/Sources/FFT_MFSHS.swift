
import Foundation
import AVFoundation
import Accelerate

private let H = 5
private let fftLength: Double = 8192.0
private var windowLength: Double = 2048.0
private var sampleRate: Double = 44100.0
private var frameSize: Double = 2048.0
private let hopSize: Double = 512.0


private let h: Double = 0.8
private let PI = atan(1.0) * 4

private var hammingWindow = [Double]()
/// 过零点位置
//public var zeroamploc = [Int]()

/// 从Data中提取音频时间序列
/// - Parameter data: 音频Data
/// - Returns: 音频时间序列
public func librosaAudioData(data: NSData) -> [Float]? {
    guard let audioFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false) else {
        print("audioFormat 创建失败")
        return nil
    }  // given NSData audio format
    guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(data.length) / 2) else {
        print("pcmBuffer 创建失败")
        return nil
    }
    pcmBuffer.frameLength = pcmBuffer.frameCapacity

    let channels = UnsafeBufferPointer(start: pcmBuffer.floatChannelData, count: Int(pcmBuffer.format.channelCount))
    data.getBytes(UnsafeMutableRawPointer(channels[0]) , length: data.length)
    
    let floatArray = Array(UnsafeBufferPointer(start: channels.baseAddress?.pointee, count:Int(pcmBuffer.frameLength)))
    return floatArray
}

/// 提取音频时间序列
/// - Parameter audioURL: 音频URL
/// - Returns:
///     - **Parameter signal**: 音频时间序列
///     - **rate**: 音频采样率
///     - **frameCount**: 音频样本帧数，即signal数组长度
public func loadAudioSignal(audioURL: URL) -> (signal: [Float], rate: Double, frameCount: Int) {
    do {
        let file = try AVAudioFile(forReading: audioURL)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)!
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(file.length))
        do {
            try file.read(into: buf!) // You probably want better error handling
        } catch {
            print(error)
        }
        let floatArray = Array(UnsafeBufferPointer(start: buf?.floatChannelData![0], count:Int(buf!.frameLength)))
        return (signal: floatArray, rate: file.fileFormat.sampleRate, frameCount: Int(file.length))
    } catch let error {
        print("loadAudioSignal AVAudioFile error, \(error.localizedDescription)")
        return (signal: [], rate: 44100, frameCount: 0)
    }
    
}


/// 将音频序列分帧后进行音高提取
/// - Parameter data: 音频时序数组
/// - Returns: 音高结果数组
public func seperateDataToFrame(data: [Double]) -> (nodeResultArray: [Float], zeroamploc: [Int], energeArray: [Float], frame: Int) {
    
    /// 数据前后各补半帧0
    let zeroFrame = [Double](repeating: 0.0, count: (Int(frameSize/2)))
    let arr:[Double] = zeroFrame + data + zeroFrame
    /// 以512为帧跳，计算帧数
    let nFrame = Int(ceilf(Float((arr.count - Int(frameSize)))/Float(hopSize)))
    var curPos:Int = 0
    var meanAmp: Double = 0
//    print("音高提取帧数: ", nFrame)
    //初始化汉明窗
    callHamming()
    /// 音高结果存放数组
    var nodeResultArray = [Float]()
    /// 过零点结果数组
    var zeroamploc = [Int]()
    /// 能量数组
    var energeArray = [Float]()
    
    for index in 0..<nFrame {
        /// 1帧数据
        let temp = arr[curPos...(curPos + Int(frameSize) - 1)].map { (item) -> Double in
            return Double(item)
        }
        meanAmp = temp.map(abs).reduce(0, +) / Double(temp.count)
        if meanAmp > 0.01 {
            let node = getNode(sampleRat: 44100, data: temp)
            nodeResultArray.append(NSString.init(format: "%.2f", node).floatValue)
            energeArray.append(Float(meanAmp))
//            print(String.localizedStringWithFormat("%.2f", node))
        } else {
            nodeResultArray.append(0.0)
//            print(0)
            energeArray.append(0.0)
            zeroamploc.append(index)
        }
        curPos += Int(hopSize)
    }
    return (nodeResultArray, zeroamploc, energeArray, nFrame)

}

/// 每帧音高获取
/// - Parameters:
///   - sampleRat: 音频采样率
///   - data: 一帧数据
/// - Returns: 音高结果
public func getNode(sampleRat: Double, data: [Double]) -> Double{
    
    sampleRate = sampleRat
    var fPitch = calcuPitcher(rawMicDat: data)
    fPitch = (fPitch <= 50) ? 0:fPitch
    var fNote: Double
    if (fPitch > 0) {
//        fNote = Int(round(69 + 12 * log(CGFloat(fPitch / 440)) / log(2.0)))
        fNote = 69 + 12 * log(Double(fPitch / 440)) / log(2.0)
    } else {
        fNote = 0
    }
    if fNote > 0 {
        fNote = fNote - 20
    }
    return fNote;
}


/// 汉明窗
public func callHamming() {
//    hammingWindow = [Double](repeating: 0, count: Int(windowLength))
//    vDSP_hamm_windowD(&hammingWindow, vDSP_Length(windowLength), Int32(vDSP_HANN_NORM))
    hammingWindow = vDSP.window(ofType: Double.self, usingSequence: .hamming, count: Int(windowLength), isHalfWindow: false)
}


public func calcuPitcher(rawMicDat: [Double]) -> Double {
    var fftResult = [Double](repeating: 0.0, count: Int(fftLength/8))
    var allFFTResult = [Double](repeating: 0.0, count: Int(fftLength))
    var fftResultNoPhase = [Double](repeating: 0.0, count: Int(fftLength))
    
    
    vDSP_vmulD(rawMicDat, 1, hammingWindow, 1, &allFFTResult, 1, vDSP_Length(windowLength))
    
    let log2Size = Int(log2(Float(fftLength)))
    let fftSetup = vDSP_create_fftsetupD(vDSP_Length(log2Size), FFTRadix(kFFTRadix2))
    
    var realPart:[Double] = allFFTResult
    var imaginaryPart:[Double] = [Double](repeating: 0.0, count: Int(fftLength))
    
    realPart.withUnsafeMutableBufferPointer { realPtr in
        imaginaryPart.withUnsafeMutableBufferPointer { imagPtr in
            var complexBuffer = DSPDoubleSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
            vDSP_fft_zipD(fftSetup!, &complexBuffer, 1, vDSP_Length(log2Size), FFTDirection(FFT_FORWARD))
            vDSP.absolute(complexBuffer, result: &fftResultNoPhase)
        }
    }
    
    vDSP_destroy_fftsetupD(fftSetup)
    
    fftResult[0..<Int(fftLength/8)] = fftResultNoPhase[0..<Int(fftLength/8)]
    
    return calculateMFSHPitch(fftResult: fftResult)
}

public func calculateMFSHPitch(fftResult: [Double]) -> Double {
    var maxItem = 0.0
    var maxIndex:vDSP_Length = 0
    vDSP_maxviD(fftResult, 1, &maxItem, &maxIndex, vDSP_Length(fftResult.count))
    var p = [Double](repeating: 0.0, count: H)
    var L:Int = 0
    let maxResultIndex:Int = Int(maxIndex)

    for i in 0..<H {
        p[i] = 0
        let temp:Double = Double(i+1)*fftLength/8.0/Double(maxResultIndex+1)
        let LTemp = floor(temp)
        L = min(10, Int(LTemp))
        for j in 0..<L-1 {
            let ifCase = round(Double(j)*Double(maxResultIndex+1)/Double(i+1))
            if ifCase != 0 {
                p[i] += fftResult[Int(ifCase - 1)] * pow(h, Double(j))
            }
        }
    }
    var pMaxItem = 0.0
    var pMaxIndex:vDSP_Length = 0
    vDSP_maxviD(p, 1, &pMaxItem, &pMaxIndex, vDSP_Length(H))
    var f0:Double = round(Double(maxResultIndex+1) / Double(pMaxIndex + 1)) / fftLength
    
    if f0 > (1100.0/sampleRate) {
        f0 = 0
    }
    //fpitch
    return (f0 * sampleRate)
    
}

