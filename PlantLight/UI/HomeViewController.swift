import UIKit
import AVFoundation

class HomeViewController: BaseVC {
    
    @IBOutlet weak var measurementContainerView: UIView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var unitTitleLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var lightSourceButton: UIButton!
    
    @IBOutlet weak var timeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var timeStepperContainer: UIView!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var lightSourceContainer: UIView!
    @IBOutlet weak var flButton: UIButton!
    @IBOutlet weak var cmhButton: UIButton!
    @IBOutlet weak var whiteLightButton: UIButton!
    @IBOutlet weak var sunlightButton: UIButton!
    
    var gradientLayer: CAGradientLayer!
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var currentPage = 0 
    private var selectedHours: Double = 12.0
    private let sensorManager = LightSensorManager.shared
    
    // 相机权限相关 UI
    private var enableCameraButton: UIButton?
    private var hasCameraPermission = false
    
    init() {
        super.init(nibName: "HomeViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestCameraPermission()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        previewLayer?.frame = view.bounds
    }
    
    private func requestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            hasCameraPermission = true
            print("camera_permission_granted".localStr)
            setupSensor()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasCameraPermission = granted
                    if granted {
                        print("camera_permission_granted".localStr)
                        self?.setupSensor()
                        self?.showBlurOverlay(false)
                    } else {
                        print("camera_permission_denied".localStr)
                        self?.showBlurOverlay(true)
                    }
                }
            }
            
        case .denied, .restricted:
            hasCameraPermission = false
            print("camera_permission_denied".localStr)
            showBlurOverlay(true)
            
        @unknown default:
            hasCameraPermission = false
            showBlurOverlay(true)
        }
    }
    
    private func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupCameraPreview()
        
        setupGradientBackground()
        
        setupCornerBrackets()
        
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.addTarget(self, action: #selector(pageControlValueChanged(_:)), for: .valueChanged)
        
        measurementContainerView.backgroundColor = .clear
        
        valueLabel.textColor = .white
        
        unitTitleLabel.textColor = .white
        unitTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        unitLabel.textColor = .white
        unitLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        lightSourceButton.backgroundColor = UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0) //
        lightSourceButton.setTitleColor(.white, for: .normal)
        lightSourceButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        timeSegmentedControl.isHidden = true
        timeStepperContainer.isHidden = true
        
        minusButton.backgroundColor = UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 0.3)
        minusButton.setTitleColor(.white, for: .normal)
        minusButton.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .light)
        plusButton.backgroundColor = UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 0.3)
        plusButton.setTitleColor(.white, for: .normal)
        plusButton.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .light)
        
        setupLightSourceButtons()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        
        updateCurrentMeasurement()
    }
    
    private func setupCameraPreview() {
        guard let session = sensorManager.session else {
            print("⚠️ Camera session not available")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        
        if let preview = previewLayer {
            view.layer.insertSublayer(preview, at: 0)
            print("✅ Camera preview layer added")
        }
    }
    
    private func setupGradientBackground() {
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7).cgColor,  // 黑色 70% 透明
            UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8).cgColor,  // 黑色 80% 透明
            UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85).cgColor  // 黑色 85% 透明
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        
        if let _ = previewLayer {
            view.layer.insertSublayer(gradientLayer, above: previewLayer)
        } else {
            view.layer.insertSublayer(gradientLayer, at: 0)
        }
        
        print("✅ Dark overlay added")
    }
    
    private func setupLightSourceButtons() {
        let buttons = [flButton, cmhButton, whiteLightButton, sunlightButton]
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        
        flButton.setImage(UIImage(systemName: "lightbulb", withConfiguration: iconConfig), for: .normal)
        cmhButton.setImage(UIImage(systemName: "lightbulb.fill", withConfiguration: iconConfig), for: .normal)
        whiteLightButton.setImage(UIImage(systemName: "light.max", withConfiguration: iconConfig), for: .normal)
        sunlightButton.setImage(UIImage(systemName: "sun.max.fill", withConfiguration: iconConfig), for: .normal)
        
        for button in buttons {
            button?.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            button?.tintColor = .white
        }
        
        updateLightSourceButtonSelection()
    }
    
    private func updateLightSourceButtonSelection() {
        let greenColor = UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0) // #4CAF50 绿色主题
        let normalColor = UIColor.white.withAlphaComponent(0.1)
        
        flButton.backgroundColor = normalColor
        cmhButton.backgroundColor = normalColor
        whiteLightButton.backgroundColor = normalColor
        sunlightButton.backgroundColor = normalColor
        
        switch sensorManager.selectedLightSource {
        case .fluorescent:
            flButton.backgroundColor = greenColor
        case .cmh:
            cmhButton.backgroundColor = greenColor
        case .whiteLight:
            whiteLightButton.backgroundColor = greenColor
        case .sunlight:
            sunlightButton.backgroundColor = greenColor
        }
    }
    
    private func setupCornerBrackets() {
        let bracketColor = UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0) // #4CAF50 绿色主题
        let bracketWidth: CGFloat = 20
        let bracketThickness: CGFloat = 3
        let bracketLength: CGFloat = 80
        
        let topLeftH = UIView()
        topLeftH.backgroundColor = bracketColor
        topLeftH.translatesAutoresizingMaskIntoConstraints = false
        measurementContainerView.addSubview(topLeftH)
        NSLayoutConstraint.activate([
            topLeftH.leadingAnchor.constraint(equalTo: measurementContainerView.leadingAnchor, constant: bracketWidth),
            topLeftH.topAnchor.constraint(equalTo: measurementContainerView.topAnchor, constant: bracketWidth),
            topLeftH.widthAnchor.constraint(equalToConstant: bracketLength),
            topLeftH.heightAnchor.constraint(equalToConstant: bracketThickness)
        ])
        
        let topLeftV = UIView()
        topLeftV.backgroundColor = bracketColor
        topLeftV.translatesAutoresizingMaskIntoConstraints = false
        measurementContainerView.addSubview(topLeftV)
        NSLayoutConstraint.activate([
            topLeftV.leadingAnchor.constraint(equalTo: measurementContainerView.leadingAnchor, constant: bracketWidth),
            topLeftV.topAnchor.constraint(equalTo: measurementContainerView.topAnchor, constant: bracketWidth),
            topLeftV.widthAnchor.constraint(equalToConstant: bracketThickness),
            topLeftV.heightAnchor.constraint(equalToConstant: bracketLength)
        ])
        
        let topRightH = UIView()
        topRightH.backgroundColor = bracketColor
        topRightH.translatesAutoresizingMaskIntoConstraints = false
        measurementContainerView.addSubview(topRightH)
        NSLayoutConstraint.activate([
            topRightH.trailingAnchor.constraint(equalTo: measurementContainerView.trailingAnchor, constant: -bracketWidth),
            topRightH.topAnchor.constraint(equalTo: measurementContainerView.topAnchor, constant: bracketWidth),
            topRightH.widthAnchor.constraint(equalToConstant: bracketLength),
            topRightH.heightAnchor.constraint(equalToConstant: bracketThickness)
        ])
        
        let topRightV = UIView()
        topRightV.backgroundColor = bracketColor
        topRightV.translatesAutoresizingMaskIntoConstraints = false
        measurementContainerView.addSubview(topRightV)
        NSLayoutConstraint.activate([
            topRightV.trailingAnchor.constraint(equalTo: measurementContainerView.trailingAnchor, constant: -bracketWidth),
            topRightV.topAnchor.constraint(equalTo: measurementContainerView.topAnchor, constant: bracketWidth),
            topRightV.widthAnchor.constraint(equalToConstant: bracketThickness),
            topRightV.heightAnchor.constraint(equalToConstant: bracketLength)
        ])
        
        let bottomLeftH = UIView()
        bottomLeftH.backgroundColor = bracketColor
        bottomLeftH.translatesAutoresizingMaskIntoConstraints = false
        measurementContainerView.addSubview(bottomLeftH)
        NSLayoutConstraint.activate([
            bottomLeftH.leadingAnchor.constraint(equalTo: measurementContainerView.leadingAnchor, constant: bracketWidth),
            bottomLeftH.bottomAnchor.constraint(equalTo: measurementContainerView.bottomAnchor, constant: -bracketWidth),
            bottomLeftH.widthAnchor.constraint(equalToConstant: bracketLength),
            bottomLeftH.heightAnchor.constraint(equalToConstant: bracketThickness)
        ])
        
        let bottomLeftV = UIView()
        bottomLeftV.backgroundColor = bracketColor
        bottomLeftV.translatesAutoresizingMaskIntoConstraints = false
        measurementContainerView.addSubview(bottomLeftV)
        NSLayoutConstraint.activate([
            bottomLeftV.leadingAnchor.constraint(equalTo: measurementContainerView.leadingAnchor, constant: bracketWidth),
            bottomLeftV.bottomAnchor.constraint(equalTo: measurementContainerView.bottomAnchor, constant: -bracketWidth),
            bottomLeftV.widthAnchor.constraint(equalToConstant: bracketThickness),
            bottomLeftV.heightAnchor.constraint(equalToConstant: bracketLength)
        ])
        
        let bottomRightH = UIView()
        bottomRightH.backgroundColor = bracketColor
        bottomRightH.translatesAutoresizingMaskIntoConstraints = false
        measurementContainerView.addSubview(bottomRightH)
        NSLayoutConstraint.activate([
            bottomRightH.trailingAnchor.constraint(equalTo: measurementContainerView.trailingAnchor, constant: -bracketWidth),
            bottomRightH.bottomAnchor.constraint(equalTo: measurementContainerView.bottomAnchor, constant: -bracketWidth),
            bottomRightH.widthAnchor.constraint(equalToConstant: bracketLength),
            bottomRightH.heightAnchor.constraint(equalToConstant: bracketThickness)
        ])
        
        let bottomRightV = UIView()
        bottomRightV.backgroundColor = bracketColor
        bottomRightV.translatesAutoresizingMaskIntoConstraints = false
        measurementContainerView.addSubview(bottomRightV)
        NSLayoutConstraint.activate([
            bottomRightV.trailingAnchor.constraint(equalTo: measurementContainerView.trailingAnchor, constant: -bracketWidth),
            bottomRightV.bottomAnchor.constraint(equalTo: measurementContainerView.bottomAnchor, constant: -bracketWidth),
            bottomRightV.widthAnchor.constraint(equalToConstant: bracketThickness),
            bottomRightV.heightAnchor.constraint(equalToConstant: bracketLength)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if sensorManager.onBrightnessUpdate != nil {
            sensorManager.startMonitoring()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sensorManager.stopMonitoring()
    }
    
    private func setupSensor() {
        sensorManager.onBrightnessUpdate = { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateValues()
            }
        }
        sensorManager.startMonitoring()
    }
    
    private func updateValues() {
        updateCurrentMeasurement()
    }
    
    private func updateCurrentMeasurement() {
        switch currentPage {
        case 0: // PPFD
            let ppfd = sensorManager.getCurrentPPFD()
            valueLabel.text = String(format: "%.2f", ppfd)
            unitTitleLabel.text = "home_ppfd_title".localStr
            unitLabel.text = "home_ppfd_unit".localStr
            lightSourceButton.setTitle("home_par_meter_info".localStr, for: .normal)
            lightSourceButton.isHidden = false
            timeSegmentedControl.isHidden = true
            timeStepperContainer.isHidden = true
            
        case 1: // DLI
            let dli = sensorManager.calculateDLI(hours: selectedHours)
            valueLabel.text = String(format: "%.3f", dli)
            unitTitleLabel.text = "home_dli_title".localStr
            unitLabel.text = "home_dli_unit".localStr
            lightSourceButton.setTitle("home_dli_meter_info".localStr, for: .normal)
            lightSourceButton.isHidden = false
            timeSegmentedControl.isHidden = false
            timeStepperContainer.isHidden = false
            timeLabel.text = "\(Int(selectedHours)) h"
            
        case 2: // Lux
            let lux = sensorManager.getCurrentLux()
            valueLabel.text = String(format: "%.0f", lux)
            unitTitleLabel.text = "home_lux_title".localStr
            unitLabel.text = "home_lux_unit".localStr
            lightSourceButton.setTitle("home_lux_meter_info".localStr, for: .normal)
            lightSourceButton.isHidden = false
            timeSegmentedControl.isHidden = true
            timeStepperContainer.isHidden = true
            
        default:
            break
        }
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left {
            currentPage = (currentPage + 1) % 3
        } else if gesture.direction == .right {
            currentPage = (currentPage - 1 + 3) % 3
        }
        pageControl.currentPage = currentPage
        
        UIView.transition(with: measurementContainerView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.updateCurrentMeasurement()
        })
    }
    
    @objc private func pageControlValueChanged(_ sender: UIPageControl) {
        
        currentPage = sender.currentPage
        
        UIView.transition(with: measurementContainerView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.updateCurrentMeasurement()
        })
    }
    
    @IBAction func lightSourceButtonTapped(_ sender: UIButton) {
        Event.add(.feature_home_help, info:  ["title":  sensorManager.selectedLightSource.title])
        showInfoModal()
    }
    
    private func showInfoModal() {
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        overlayView.alpha = 0
        overlayView.tag = 9999
        
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 20
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        let greenLabel = UIButton()
        greenLabel.backgroundColor = UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0) // #4CAF50
        greenLabel.layer.cornerRadius = 12
        greenLabel.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        greenLabel.setTitleColor(.white, for: .normal)
        greenLabel.isUserInteractionEnabled = false
        greenLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descLabel = UILabel()
        descLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descLabel.textColor = .black
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .center
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let learnMoreBtn = UIButton()
        learnMoreBtn.backgroundColor = .black
        learnMoreBtn.layer.cornerRadius = 25
        learnMoreBtn.setTitle("info_modal_learn_more".localStr, for: .normal)
        learnMoreBtn.setTitleColor(.white, for: .normal)
        learnMoreBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        learnMoreBtn.translatesAutoresizingMaskIntoConstraints = false
        learnMoreBtn.addTarget(self, action: #selector(learnMoreTapped), for: .touchUpInside)
        
        switch currentPage {
        case 0: // PPFD
            greenLabel.setTitle("info_modal_par_title".localStr, for: .normal)
            descLabel.text = "info_modal_par_description".localStr
        case 1: // DLI
            greenLabel.setTitle("info_modal_dli_title".localStr, for: .normal)
            descLabel.text = "info_modal_dli_description".localStr
        case 2: // Lux
            greenLabel.setTitle("info_modal_lux_title".localStr, for: .normal)
            descLabel.text = "info_modal_lux_description".localStr
        default:
            break
        }
        
        cardView.addSubview(greenLabel)
        cardView.addSubview(descLabel)
        cardView.addSubview(learnMoreBtn)
        overlayView.addSubview(cardView)
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 40),
            cardView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -40),
            
            greenLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            greenLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            greenLabel.heightAnchor.constraint(equalToConstant: 40),
            greenLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            
            descLabel.topAnchor.constraint(equalTo: greenLabel.bottomAnchor, constant: 30),
            descLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            descLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            
            learnMoreBtn.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 30),
            learnMoreBtn.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            learnMoreBtn.heightAnchor.constraint(equalToConstant: 50),
            learnMoreBtn.widthAnchor.constraint(equalToConstant: 160),
            learnMoreBtn.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -30)
        ])
        
        UIView.animate(withDuration: 0.3) {
            overlayView.alpha = 1
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissInfoModal))
        overlayView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissInfoModal() {
        if let overlayView = view.viewWithTag(9999) {
            UIView.animate(withDuration: 0.3, animations: {
                overlayView.alpha = 0
            }) { _ in
                overlayView.removeFromSuperview()
            }
        }
    }
    
    @objc private func learnMoreTapped() {
        if let overlayView = view.viewWithTag(9999) {
            UIView.animate(withDuration: 0.3, animations: {
                overlayView.alpha = 0
            }) { _ in
                overlayView.removeFromSuperview()
            }
        }
        Event.add(.feature_home_help_learn_more)
        let detailVC = GuideDetailViewController()
        detailVC.url = AppBasic.config.common_guide_url
        switch currentPage {
        case 1:
            detailVC.guideType = .dli
        case 2:
            detailVC.guideType = .lux
        default:
            detailVC.guideType = .par
        }
        present(detailVC, animated: true)
    }
    
    @IBAction func flButtonTapped(_ sender: UIButton) {
        Event.add(.feature_home_fl_click)
        sensorManager.selectedLightSource = .fluorescent
        updateLightSourceButtonSelection()
        updateValues()
    }
    
    @IBAction func cmhButtonTapped(_ sender: UIButton) {
        Event.add(.feature_home_cmh_click)
        sensorManager.selectedLightSource = .cmh
        updateLightSourceButtonSelection()
        updateValues()
    }
    
    @IBAction func whiteLightButtonTapped(_ sender: UIButton) {
        Event.add(.feature_home_white_light_click)
        sensorManager.selectedLightSource = .whiteLight
        updateLightSourceButtonSelection()
        updateValues()
    }
    
    @IBAction func sunlightButtonTapped(_ sender: UIButton) {
        Event.add(.feature_home_sunlight_click)
        sensorManager.selectedLightSource = .sunlight
        updateLightSourceButtonSelection()
        updateValues()
    }
    
    @IBAction func timeSegmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedHours = 12
        case 1:
            selectedHours = 18
        case 2:
            selectedHours = 24
        default:
            break
        }
        updateValues()
    }
    
    @IBAction func minusButtonTapped(_ sender: UIButton) {
        if selectedHours > 1 {
            selectedHours -= 1
            updateValues()
        }
    }
    
    @IBAction func plusButtonTapped(_ sender: UIButton) {
        if selectedHours < 24 {
            selectedHours += 1
            updateValues()
        }
    }
    
    private func showBlurOverlay(_ show: Bool) {
        // 移除按钮
        if let button = view.viewWithTag(8889) {
            button.removeFromSuperview()
        }
        enableCameraButton = nil
        valueLabel.isHidden = false
        guard show else { return }
        let enableButton = UIButton(type: .system)
        enableButton.setTitle("camera_permission_enable".localStr, for: .normal)
        enableButton.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        enableButton.setTitleColor(.white, for: .normal)
        enableButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        enableButton.layer.cornerRadius = 25
        enableButton.layer.borderWidth = 1.5
        enableButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        enableButton.translatesAutoresizingMaskIntoConstraints = false
        enableButton.tag = 8889
        enableButton.addTarget(self, action: #selector(enableCameraButtonTapped), for: .touchUpInside)
        view.addSubview(enableButton)
        NSLayoutConstraint.activate([
            enableButton.centerXAnchor.constraint(equalTo: valueLabel.centerXAnchor),
            enableButton.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            enableButton.widthAnchor.constraint(equalToConstant: 200),
            enableButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        enableCameraButton = enableButton
        valueLabel.isHidden = true
    }
    
    @objc private func enableCameraButtonTapped() {
        // 显示确认弹窗
        let alert = UIAlertController(
            title: "camera_permission_enable_title".localStr,
            message: "camera_permission_enable_message".localStr,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "camera_permission_settings".localStr, style: .default) { _ in
            // 跳转到设置页
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "camera_permission_cancel".localStr, style: .cancel))
        
        present(alert, animated: true)
    }
}

