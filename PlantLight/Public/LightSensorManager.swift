import UIKit
import AVFoundation

enum LightSourceType: Int {
    case fluorescent = 0
    case cmh = 1
    case whiteLight = 2
    case sunlight = 3
    
    var title: String {
        switch self {
        case .fluorescent: return "home_light_source_fl".localStr
        case .cmh: return "home_light_source_cmh".localStr
        case .whiteLight: return "home_light_source_white".localStr
        case .sunlight: return "home_light_source_sun".localStr
        }
    }
    
    var conversionFactor: Double {
        switch self {
        case .fluorescent:
            // 荧光灯（T5/T8 cool white）
            // 参考：约 70 lux ≈ 1 μmol/m²/s
            return 0.0143  // 1/70
        case .cmh:
            // CMH（陶瓷金属卤素灯）- 接近自然光谱
            // 参考：约 52-54 lux ≈ 1 μmol/m²/s
            return 0.0189  // 1/53
        case .whiteLight:
            // 白炽灯 - 更多红外辐射，PAR 效率低
            // 参考：约 80-100 lux ≈ 1 μmol/m²/s
            return 0.0120  // 1/83
        case .sunlight:
            // 自然阳光（标准值）
            // 参考：约 54 lux ≈ 1 μmol/m²/s
            return 0.0185  // 1/54
        }
    }
}

class LightSensorManager: NSObject {
    static let shared = LightSensorManager()
    
    private var captureSession: AVCaptureSession?
    private var videoDevice: AVCaptureDevice?
    private var currentLux: Double = 0 // 默认值
    private var monitorTimer: Timer?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    var onBrightnessUpdate: ((CGFloat) -> Void)?
    var selectedLightSource: LightSourceType = .fluorescent
    
    private var calibrationConstant: Double {
        get {
            return UserDefaults.standard.double(forKey: "LuxCalibrationConstant") != 0 
                ? UserDefaults.standard.double(forKey: "LuxCalibrationConstant") 
            : 0.9532  // 默认值
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "LuxCalibrationConstant")
        }
    }
    
    var session: AVCaptureSession? {
        return captureSession
    }
    
    private override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        print("🎥 Setting up camera...")
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .low
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("❌ Failed to get front camera")
            return
        }
        
        videoDevice = device
        print("✅ Got front camera: \(device.localizedName)")
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
                print("✅ Added camera input")
            }
            
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput?.alwaysDiscardsLateVideoFrames = true
            
            let outputQueue = DispatchQueue(label: "videoOutputQueue")
            videoOutput?.setSampleBufferDelegate(self, queue: outputQueue)
            
            if let output = videoOutput, captureSession?.canAddOutput(output) == true {
                captureSession?.addOutput(output)
                print("✅ Added video output")
            }
            
            try device.lockForConfiguration()
            
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            device.unlockForConfiguration()
            print("✅ Camera configured")
            
        } catch {
            print("❌ Failed to setup camera: \(error)")
        }
    }
    
    func startMonitoring() {
        print("🚀 Starting monitoring...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let session = self?.captureSession else { return }
            
            if !session.isRunning {
                session.startRunning()
                print("✅ Camera session started")
            }
        }
        
        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateBrightness()
        }
        
        print("✅ Monitor timer started")
    }
    
    func stopMonitoring() {
        print("⏸️ Stopping monitoring...")
        monitorTimer?.invalidate()
        monitorTimer = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
            print("✅ Camera session stopped")
        }
    }
    
    private func updateBrightness() {
        guard let device = videoDevice else {
            let screenBrightness = UIScreen.main.brightness
            currentLux = Double(screenBrightness) * 1000
            onBrightnessUpdate?(screenBrightness)
            return
        }
        do {
            try device.lockForConfiguration()
            
            // 读取相机参数
            let iso = device.iso
            let exposureDuration = device.exposureDuration.seconds
            let aperture = device.lensAperture  // f-number
            
            // 计算 EV (Exposure Value)
            // EV = log2(aperture² / shutterSpeed) - log2(ISO/100)
            // 简化公式：EV = log2(aperture² / (shutterSpeed × ISO/100))
            let shutterSpeed = exposureDuration  // 快门速度（秒）
            
            // 防止除零错误
            guard shutterSpeed > 0 else {
                device.unlockForConfiguration()
                return
            }
            // 计算 EV 值
            // EV = log2(N²/t × 100/S)
            // N = 光圈值(f-number), t = 曝光时间(秒), S = ISO
            let ev = log2(Double((aperture * aperture)) / shutterSpeed) - log2(Double(iso) / 100.0)
            
            // 将 EV 转换为 lux
            // 标准公式：lux ≈ 2.5 × 2^EV × K
            // K 是校准常数，根据相机传感器特性调整
            // iPhone 前置摄像头的典型校准值约为 0.5-0.8
            // 计算 lux（使用可配置的校准常数）
            currentLux = 2.5 * pow(2.0, ev) * calibrationConstant
            // 限制在合理范围内
            // 室内：50-500 lux
            // 办公室：300-500 lux  
            // 阴天室外：1000-10000 lux
            // 晴天室外：10000-100000 lux
            currentLux = max(1, min(100000, currentLux))
            
            device.unlockForConfiguration()
            
            // 通知观察者
            let brightness = CGFloat(min(1.0, currentLux / 1000.0))
            DispatchQueue.main.async { [weak self] in
                self?.onBrightnessUpdate?(brightness)
            }
            
            print("📸 ISO: \(iso) | 曝光: \(String(format: "%.4f", exposureDuration))s | 光圈: f/\(String(format: "%.1f", aperture)) | EV: \(String(format: "%.2f", ev)) | Lux: \(String(format: "%.1f", currentLux))")
            
        } catch {
            print("❌ Failed to read camera settings: \(error)")
            // Fallback
            let screenBrightness = UIScreen.main.brightness
            currentLux = Double(screenBrightness) * 1000
            onBrightnessUpdate?(screenBrightness)
        }
    }
    
    func getCurrentLux() -> Double {
        return currentLux
    }
    
    /// 从 lux 计算 PPFD (光合光量子通量密度)
    /// - Returns: PPFD 值，单位：μmol/m²/s (微摩尔每平方米每秒)
    func getCurrentPPFD() -> Double {
        let lux = getCurrentLux()
        let ppfd = lux * selectedLightSource.conversionFactor
        return ppfd
    }
    
    /// 计算 DLI (Daily Light Integral，日光积分)
    /// - Parameter hours: 光照时间（小时）
    /// - Returns: DLI 值，单位：mol/m²/day (摩尔每平方米每天)
    /// 
    /// 公式说明：
    /// - DLI = PPFD (μmol/m²/s) × 光照时间(h) × 3600(s/h) / 1,000,000(μmol/mol)
    /// - 简化：DLI = PPFD × hours × 0.0036
    func calculateDLI(hours: Double) -> Double {
        let ppfd = getCurrentPPFD()
        
        // 单位转换：
        // μmol/m²/s → mol/m²/day
        // 1 hour = 3600 seconds
        // 1 mol = 1,000,000 μmol
        let dli = ppfd * hours * 3600.0 / 1_000_000.0  // 使用明确的转换
        
        return dli
    }
    
    /// 根据植物类型推荐的 DLI 参考值：
    /// - 低光植物（蕨类、绿萝）：5-10 mol/m²/day
    /// - 中光植物（多肉、观叶植物）：10-20 mol/m²/day
    /// - 高光植物（开花植物、蔬菜）：15-30 mol/m²/day
    /// - 极高光植物（番茄、辣椒）：20-40 mol/m²/day
    
    /// 计算达到目标 DLI 所需的光照时间
    /// - Parameter targetDLI: 目标 DLI 值 (mol/m²/day)
    /// - Returns: 所需光照时间（小时），如果当前光照不足返回 nil
    func calculateRequiredHours(forTargetDLI targetDLI: Double) -> Double? {
        let ppfd = getCurrentPPFD()
        
        // PPFD 太低（小于 10 μmol/m²/s），无法达到目标
        guard ppfd >= 10.0 else {
            return nil
        }
        
        // 反推公式：hours = DLI / (PPFD × 0.0036)
        let requiredHours = targetDLI / (ppfd * 0.0036)
        
        // 限制在合理范围内（0-24 小时）
        return min(24.0, max(0, requiredHours))
    }
    
    /// 获取当前光照水平的描述
    /// - Returns: 光照水平描述
    func getLightLevelDescription() -> String {
        let ppfd = getCurrentPPFD()
        
        switch ppfd {
        case 0..<50:
            return "极低光照（不适合植物生长）"
        case 50..<100:
            return "低光照（适合耐阴植物）"
        case 100..<200:
            return "中低光照（适合室内观叶植物）"
        case 200..<400:
            return "中等光照（适合多数室内植物）"
        case 400..<600:
            return "中高光照（适合开花植物）"
        case 600..<1000:
            return "高光照（适合蔬菜、多肉）"
        default:
            return "极高光照（接近室外水平）"
        }
    }
    
    /// 校准 lux 读数
    /// - Parameters:
    ///   - referenceLux: 专业设备测量的实际 lux 值
    /// - Returns: 校准后的常数值
    @discardableResult
    func calibrate(withReferenceLux referenceLux: Double) -> Double {
        guard let device = videoDevice else {
            print("❌ 相机不可用，无法校准")
            return calibrationConstant
        }
        
        do {
            try device.lockForConfiguration()
            
            let iso = device.iso
            let exposureDuration = device.exposureDuration.seconds
            let aperture = device.lensAperture
            let shutterSpeed = exposureDuration
            
            guard shutterSpeed > 0 else {
                device.unlockForConfiguration()
                return calibrationConstant
            }
            
            // 计算当前的 EV 值
            let ev = log2(Double((aperture * aperture)) / shutterSpeed) - log2(Double(iso) / 100.0)
            
            // 反推校准常数
            // referenceLux = 2.5 × 2^EV × K
            // K = referenceLux / (2.5 × 2^EV)
            let newCalibrationConstant = referenceLux / (2.5 * pow(2.0, ev))
            
            device.unlockForConfiguration()
            
            // 限制校准常数在合理范围内（0.1 ~ 2.0）
            let clampedConstant = max(0.1, min(2.0, newCalibrationConstant))
            
            // 保存校准常数
            calibrationConstant = clampedConstant
            
            print("✅ 校准成功！")
            print("   参考值: \(String(format: "%.1f", referenceLux)) lux")
            print("   新校准常数: \(String(format: "%.3f", clampedConstant))")
            print("   EV: \(String(format: "%.2f", ev))")
            
            return clampedConstant
            
        } catch {
            print("❌ 校准失败: \(error)")
            return calibrationConstant
        }
    }
    
    /// 重置校准为默认值
    func resetCalibration() {
        calibrationConstant = 0.65
        print("✅ 校准已重置为默认值: 0.65")
    }
    
    /// 获取当前校准常数
    func getCalibrationConstant() -> Double {
        return calibrationConstant
    }
    
    deinit {
        stopMonitoring()
    }
}

extension LightSensorManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    }
}
