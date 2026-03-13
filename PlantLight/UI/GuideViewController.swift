import UIKit
import WebKit

struct GuideItem {
    let imageName: String
    let title: String
    let subtitle: String
    let url: String
}

class GuideViewController: BaseVC {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    init() {
        super.init(nibName: "GuideViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private lazy var guideItems: [GuideItem] = [
        GuideItem(
            imageName: "guide_1.png",
            title: "guide_card_1_title".localStr,
            subtitle: "guide_card_1_subtitle".localStr,
            url: "\(Constant.apiHost)/pages/optimal_lighting.html"
        ),
        GuideItem(
            imageName: "guide_2.png",
            title: "guide_card_2_title".localStr,
            subtitle: "guide_card_2_subtitle".localStr,
            url: "\(Constant.apiHost)/pages/measure_light.html"
        ),
        GuideItem(
            imageName: "guide_3.png",
            title: "guide_card_3_title".localStr,
            subtitle: "guide_card_3_subtitle".localStr,
            url: "\(Constant.apiHost)/pages/measurement_values.html"
        ),
        GuideItem(
            imageName: "guide_4.png",
            title: "guide_card_4_title".localStr,
            subtitle: "guide_card_4_subtitle".localStr,
            url: "\(Constant.apiHost)/pages/diffuser_required.html"
        ),
        GuideItem(
            imageName: "guide_5.png",
            title: "guide_card_5_title".localStr,
            subtitle: "guide_card_5_subtitle".localStr,
            url: "\(Constant.apiHost)/pages/light_source_setting.html"
        ),
        GuideItem(
            imageName: "guide_6.png",
            title: "guide_card_6_title".localStr,
            subtitle: "guide_card_6_subtitle".localStr,
            url: "\(Constant.apiHost)/pages/common_mistakes.html"
        ),
        GuideItem(
            imageName: "guide_7.png",
            title: "guide_card_7_title".localStr,
            subtitle: "guide_card_7_subtitle".localStr,
            url: "\(Constant.apiHost)/pages/measure_underwater.html"
        ),
        GuideItem(
            imageName: "guide_8.png",
            title: "guide_card_8_title".localStr,
            subtitle: "guide_card_8_subtitle".localStr,
            url: "\(Constant.apiHost)/pages/calibrate_plantbright.html"
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    private func setupUI() {
        view.backgroundColor = .appBackground
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        headerLabel.text = "guide_title".localStr
        headerLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        headerLabel.textColor = .appTextPrimary
        
        descriptionLabel.configureAttrText("guide_subtitle".localStr, font: UIFont.systemFont(ofSize: 17, weight: .bold))
        descriptionLabel.numberOfLines = 0
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(GuideTableViewCell.self, forCellReuseIdentifier: "GuideCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        tabBarController?.selectedIndex = 0
    }
}

extension GuideViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return guideItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GuideCell", for: indexPath) as! GuideTableViewCell
        let item = guideItems[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = guideItems[indexPath.row]
        Event.add(.feature_guide_item_click, info: ["title": item.title])
        let detailVC = GuideDetailViewController()
        detailVC.url = item.url
        present(detailVC, animated: true)
    }
}

class GuideTableViewCell: UITableViewCell {
    
    private let cardView = UIView()
    private let guideImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let viewButton = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        guideImageView.contentMode = .scaleAspectFill
        guideImageView.clipsToBounds = true
        guideImageView.layer.cornerRadius = 12
        guideImageView.backgroundColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 0.1)
        guideImageView.tintColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
        guideImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(guideImageView)
        
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor(red: 117/255, green: 117/255, blue: 117/255, alpha: 1.0)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)
        
        viewButton.setTitle("guide_view_button".localStr, for: .normal)
        viewButton.setTitleColor(.white, for: .normal)
        viewButton.backgroundColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)
        viewButton.layer.cornerRadius = 20
        viewButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        viewButton.translatesAutoresizingMaskIntoConstraints = false
        viewButton.isUserInteractionEnabled = false
        cardView.addSubview(viewButton)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            guideImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 15),
            guideImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 15),
            guideImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -15),
            guideImageView.heightAnchor.constraint(equalToConstant: 150),
            
            titleLabel.topAnchor.constraint(equalTo: guideImageView.bottomAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            viewButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 15),
            viewButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            viewButton.widthAnchor.constraint(equalToConstant: 120),
            viewButton.heightAnchor.constraint(equalToConstant: 40),
            viewButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -15)
        ])
    }
    
    func configure(with item: GuideItem) {
        guideImageView.image = UIImage(named: item.imageName)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}

class GuideDetailViewController: BaseVC {
    
    enum GuideType {
        case par
        case dli
        case lux
    }
    
    var url: String?
    var guideType: GuideType?
    
    private let closeButton = UIButton(type: .system)
    private var webView: WKWebView!
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupUI()
        loadContent()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.contentInset = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
        view.addSubview(webView)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        activityIndicator.color = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadContent() {
        guard let urlStr = url else { return }
        
        if !urlStr.isEmpty, let url = URL(string: urlStr) {
            activityIndicator.startAnimating()
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

extension GuideDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        guard let guideType = guideType else { return }
        
        // 根据类型定义要查找的关键文字
        let targetText: String
        switch guideType {
        case .par:
            targetText = "PAR"
        case .dli:
            targetText = "DLI"
        case .lux:
            targetText = "Beleuchtungsstärke"
        }
        
        // JavaScript: 查找包含目标文字的元素并滚动到该位置
        let scrollScript = """
            (function() {
                var targetText = '\(targetText)';
                var allElements = document.body.getElementsByTagName('*');
                var targetElement = null;
                var minLength = 999999;
                
                for (var i = 0; i < allElements.length; i++) {
                    var element = allElements[i];
                    var text = element.textContent || element.innerText;
                    
                    if (text && text.includes(targetText)) {
                        if (element.tagName.match(/^H[1-6]$/)) {
                            targetElement = element;
                            break;
                        }
                        if (text.length < minLength) {
                            minLength = text.length;
                            targetElement = element;
                        }
                    }
                }
                if (targetElement) {
                    var elementRect = targetElement.getBoundingClientRect();
                    var absoluteTop = elementRect.top + window.pageYOffset;
                    var offset = 20; 
                    
                    window.scrollTo({
                        top: absoluteTop - offset,
                        behavior: 'smooth'
                    });
                    
                    return { success: true, text: targetText };
                } else {
                    return { success: false, text: targetText };
                }
            })();
        """
        
        // 延迟执行以确保页面 DOM 完全加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            webView.evaluateJavaScript(scrollScript) { result, error in
                if let _ = error {
                } else if let resultDict = result as? [String: Any],
                          let success = resultDict["success"] as? Bool,
                          let _ = resultDict["text"] as? String {
                    if success {
                    } else {
                    }
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
    }
}

