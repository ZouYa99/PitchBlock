//
//  RealPitchService.swift
//  SingStar
//
//  Created by llj on 2020/12/1.
//  Copyright © 2020 Sincere. All rights reserved.
//

import Foundation
import AVFoundation

/// 录音队列回调函数
/// - Parameters:
///   - inUserData: 一个自定义结构，包含音频队列的状态数据
///   - inAQ: 调用回调函数的音频队列
///   - inBuffer: 包含音频数据的音频队列缓冲区
///   - inStartTime: 当前音频数据的时间戳，用于同步
///   - inNumberPacketDescription: inPacketDescs参数中的数据包描述的数量。录制VBR（动态比特率）格式时音频队列会提供该参数值，CBR（固定比特率）格式时值为0
///   - inPacketDescs: 音频数据中一组包的描述，录制VBR格式数据时需要将值传递给AudioFileWritePackets函数
public func RPAudioQueueInputCallback(inUserData: UnsafeMutableRawPointer?,
                               inAQ: AudioQueueRef,
                               inBuffer: AudioQueueBufferRef,
                               inStartTime: UnsafePointer<AudioTimeStamp>,
                               inNumberPacketDescription: UInt32,
                               inPacketDescs: UnsafePointer<AudioStreamPacketDescription>?) {
    //转换为指定类型
    let rpService = unsafeBitCast(inUserData!, to:RealPitchService.self)
    rpService.writePackets(inBuffer: inBuffer)
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil);
    
//    print("startingPacketCount: \(rpService.startingPacketCount), maxPacketCount: \(rpService.maxPacketCount)")
    if (rpService.maxPacketCount <= rpService.startingPacketCount) {
        rpService.stopRecord()
        rpService.isRecording = false
    }
}

public class RealPitchService {
    /// 队列的buffer个数
    let kNumberBuffers: Int = 3
//    var buffer: UnsafeMutableRawPointer
    var audioQueueObject: AudioQueueRef?
    /// 记录音频数据的文件的音频文件对象
    public var mAudioFile: AudioFileID?
    /// 初始packet数量
    var startingPacketCount: UInt32
    let bytesPerPacket: UInt32 = 2
    /// 每个音频队列缓冲区的大小(以字节为单位)
    var bufferByteSize: UInt32 = 0
    /// 录音最大时长
    let maxSeconds: UInt32 = 3600
    /// 每次回调时长,单位秒
    let second = 0.1
    /// 每次回调所需写入的packet的数量 = 采样频率 * 每次回调时长
    let numPacketsToWrite: UInt32
    /// 当前录音的最大写入packet数量 = 采样频率 * 录音最大时长
    var maxPacketCount: UInt32
    /// 录音采样频率
    let sampleRate = 44100.0
    /// 音频格式
    var audioFormat: AudioStreamBasicDescription {
        return AudioStreamBasicDescription(mSampleRate: sampleRate,
                                           mFormatID: kAudioFormatLinearPCM,
                                           mFormatFlags: AudioFormatFlags(kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked),
                                           mBytesPerPacket: 2,
                                           mFramesPerPacket: 1,
                                           mBytesPerFrame: 2,
                                           mChannelsPerFrame: 1,
                                           mBitsPerChannel: 16,
                                           mReserved: 0)
    }
    /// 录音开始标志
    var isRecording:Bool = false
    
    /// 实时音高检测队列
    let realPitchQueue = DispatchQueue(label: "pitch_detect")
    
    /// 提示音是否开始播放
    var isStandardPlaying = false
    
//    var time = Date().timeIntervalSince1970
    
    
    init() {
        startingPacketCount = 0
        numPacketsToWrite = UInt32(sampleRate * second)
        maxPacketCount = (UInt32(sampleRate) * maxSeconds)
//        buffer = UnsafeMutableRawPointer(malloc(Int(maxPacketCount * bytesPerPacket)))
        
//        print("startRecord")
//        guard audioQueueObject == nil else  { return }
//        prepareForRecord()
        updateStandardPlayingState()
    }
    
    deinit {
//        buffer.deallocate()
        print("RealPitchService 已销毁")
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateStandardPlayingState() {
        NotificationCenter.default.addObserver(self, selector: #selector(standardPlayingChanged(note:)), name: NSNotification.Name("C3PitchStarted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(standardPlayingChanged(note:)), name: NSNotification.Name("C3PitchEnded"), object: nil)
    }
    
    @objc func standardPlayingChanged(note: Notification) {
        if let value = note.userInfo?["flag"], let flag = value as? Bool {
            isStandardPlaying = flag
            print("flag: ", flag)
        }
    }
    func setupAudioSession() {
        do{
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker])
//            try AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)
        }catch let error {
            print(error.localizedDescription)
        }
    }
    
    func startRecord() {
//        print("startRecord")
        setupAudioSession()
        guard audioQueueObject == nil else  { return }
        prepareForRecord()
        let err: OSStatus = AudioQueueStart(audioQueueObject!, nil)
        print("RP err: \(err)")
        isRecording = true
//        time = Date().timeIntervalSince1970
    }
    

    func stopRecord() {
        if isRecording {
            isRecording = false
            AudioQueueStop(audioQueueObject!, true)
            AudioQueueDispose(audioQueueObject!, true)
            audioQueueObject = nil
        }
        
    }
    

    private func prepareForRecord() {
        print("prepareForRecord")
        var audioFormat = self.audioFormat
    
        //创建一个录音队列
        if AudioQueueNewInput(&audioFormat,
                              RPAudioQueueInputCallback,
                              unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
                              CFRunLoopGetCurrent(),
                              CFRunLoopMode.commonModes.rawValue,
                              0,
                              &audioQueueObject) == noErr {
            print("录音队列创建成功!")
        } else {
            print("录音队列创建失败!!")
            return
        }
        
        // 获取设置的音频流格式
        var dataFormatSize: UInt32 = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        //用以下方法验证获取到音频格式是否与我们设置的相符
        if AudioQueueGetProperty(audioQueueObject!, kAudioQueueProperty_StreamDescription, &audioFormat, &dataFormatSize) == noErr {
            print("音频流格式设置成功!")
        } else {
            print("音频流格式设置失败!!")
            return
        }
        
        
        startingPacketCount = 0;
        var buffers = Array<AudioQueueBufferRef?>(repeating: nil, count: kNumberBuffers)
        /// 计算Audio Queue中每个buffer的大小
        bufferByteSize = numPacketsToWrite * audioFormat.mBytesPerPacket
        // 内存分配,入队
        for bufferIndex in 0 ..< buffers.count {
            AudioQueueAllocateBuffer(audioQueueObject!, bufferByteSize, &buffers[bufferIndex])
            AudioQueueEnqueueBuffer(audioQueueObject!, buffers[bufferIndex]!, 0, nil)
        }
        
        
    }
    
    func writePackets(inBuffer: AudioQueueBufferRef) {
        //缓冲区中数据的总字节数除以每个数据包的(常数)字节数
        var numPackets: UInt32 = (inBuffer.pointee.mAudioDataByteSize / bytesPerPacket)
        if ((maxPacketCount - startingPacketCount) < numPackets) {
            numPackets = (maxPacketCount - startingPacketCount)
        }
//        print("writePackets mAudioDataByteSize: \(inBuffer.pointee.mAudioDataByteSize), numPackets: \(numPackets)")
        
        // 获取每次回调的buffer
        let tempData = NSData(bytes: inBuffer.pointee.mAudioData, length: Int(inBuffer.pointee.mAudioDataByteSize))
        let audioData = librosaBufferData(data: tempData)
        realPitchQueue.async {
            let pitchesResult = self.pitchdetect(data: audioData)
            
            var pitch = self.calNonZeroAverage(with: pitchesResult.nodeArray) + 20.0
            if self.isStandardPlaying {
                pitch = 60.0
            }
            NotificationCenter.default.post(name: NSNotification.Name("realPitch"), object: self, userInfo: ["pitch": pitch])
//           print("pitch: \(pitch)")
        }
        
        if 0 < numPackets {
    
             startingPacketCount += numPackets
        }
        
    }
    
    private func calNonZeroAverage(with arr: [Float]) -> Float {
        let nonZeroArr = arr.filter { $0 != 0 }
        if nonZeroArr.count == 0 {
            return 0.0
        } else {
            return nonZeroArr.reduce(0, +) / Float(nonZeroArr.count)
        }
    }
    
    
}

extension RealPitchService {
    
    private func librosaBufferData(data nodeData: NSData) -> [Double] {
        let wavData = writewaveFileHeader(input: nodeData, totalAudioLen: Int64(nodeData.count), totalDataLen: Int64(nodeData.count+36), longSampleRate: 44100, channels: 1, byteRate: Int64(16*44100/8)) as Data
//        print("nodeData count: \(nodeData.count)")
//        print("wavData count: \(wavData.count)")
        let wavUrl = writeTempDataToFile(data: wavData)
        let audioData = loadAudioSignal(audioURL: wavUrl!).signal.map(Double.init)
        return audioData
//        let wavData = writewaveFileHeader(input: nodeData, totalAudioLen: Int64(nodeData.count), totalDataLen: Int64(nodeData.count+36), longSampleRate: 44100, channels: 1, byteRate: Int64(16*44100/8)) as NSData
//        guard let audioData = librosaAudioData(data: wavData) else {
//            print("no audio data")
//            return []
//        }
//        return audioData.map(Double.init)
    }
    /// 分片音高提取
    /// - Parameter audioData: 音频时间序列
    /// - Returns: （音高数组，过零点数组，帧数）
    private func pitchdetect(data audioData:[Double]) -> (nodeArray: [Float], zeroamploc: [Int], energeArray: [Float], frame: Int) {
        let pitchesResult = seperateDataToFrame(data: audioData)
        let nodeArray = pitchesResult.nodeResultArray
        let zeroamploc = pitchesResult.zeroamploc
        let energeArray = pitchesResult.energeArray
        let frame = pitchesResult.frame
        return (nodeArray, zeroamploc, energeArray, frame)
    }
    
    private func writeTempDataToFile(data: Data) -> URL? {
        var fileUrl:URL?
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            fileUrl = dir.appendingPathComponent("pitch.wav")
//            print(fileUrl!)
            do {
                try data.write(to: fileUrl!)
            } catch {
                print(error)
            }
        }
        return fileUrl
    }
    
    private func writewaveFileHeader(input: NSData, totalAudioLen: Int64, totalDataLen: Int64, longSampleRate: Int64, channels: Int, byteRate: Int64) -> NSMutableData{
        var header: [UInt8] = Array(repeating: 0, count: 44)
        let postData:NSMutableData = NSMutableData()
        // RIFF/WAVE header
        header[0] = UInt8(ascii: "R")
        header[1] = UInt8(ascii: "I")
        header[2] = UInt8(ascii: "F")
        header[3] = UInt8(ascii: "F")
        header[4] = (UInt8)(totalDataLen & 0xff)
        header[5] = (UInt8)((totalDataLen >> 8) & 0xff)
        header[6] = (UInt8)((totalDataLen >> 16) & 0xff)
        header[7] = (UInt8)((totalDataLen >> 24) & 0xff)
        
        //WAVE
        header[8] = UInt8(ascii: "W")
        header[9] = UInt8(ascii: "A")
        header[10] = UInt8(ascii: "V")
        header[11] = UInt8(ascii: "E")
        
        // 'fmt' chunk
        header[12] = UInt8(ascii: "f")
        header[13] = UInt8(ascii: "m")
        header[14] = UInt8(ascii: "t")
        header[15] = UInt8(ascii: " ")
        
        // 4 bytes: size of 'fmt ' chunk
        header[16] = 16
        header[17] = 0
        header[18] = 0
        header[19] = 0
        
        // format = 1
        header[20] = 1
        header[21] = 0
        header[22] = UInt8(channels)
        header[23] = 0
        
        header[24] = (UInt8)(longSampleRate & 0xff)
        header[25] = (UInt8)((longSampleRate >> 8) & 0xff)
        header[26] = (UInt8)((longSampleRate >> 16) & 0xff)
        header[27] = (UInt8)((longSampleRate >> 24) & 0xff)
        
        header[28] = (UInt8)(byteRate & 0xff)
        header[29] = (UInt8)((byteRate >> 8) & 0xff)
        header[30] = (UInt8)((byteRate >> 16) & 0xff)
        header[31] = (UInt8)((byteRate >> 24) & 0xff)
        
        // block align
        header[32] = UInt8(2 * 16 / 8)
        header[33] = 0
        
        // bits per sample
        header[34] = 16
        header[35] = 0
        
        //data
        header[36] = UInt8(ascii: "d")
        header[37] = UInt8(ascii: "a")
        header[38] = UInt8(ascii: "t")
        header[39] = UInt8(ascii: "a")
        header[40] = UInt8(totalAudioLen & 0xff)
        header[41] = UInt8((totalAudioLen >> 8) & 0xff)
        header[42] = UInt8((totalAudioLen >> 16) & 0xff)
        header[43] = UInt8((totalAudioLen >> 24) & 0xff)
        
        postData.append(header, length: header.count)
        postData.append(input as Data)
        
        return postData
    }
}

