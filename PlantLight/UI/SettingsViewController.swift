import UIKit
import MessageUI

enum SettingItem {
    case share
    case rate
    case contact
    case privacy
    case userManual
    
    var title: String {
        switch self {
        case .share: return "settings_share".localStr
        case .rate: return "settings_rate".localStr
        case .contact: return "settings_contact".localStr
        case .privacy: return "settings_privacy".localStr
        case .userManual: return "settings_manual".localStr
        }
    }
    
    var icon: String {
        switch self {
        case .share: return "square.and.arrow.up"
        case .rate: return "star.fill"
        case .contact: return "envelope.fill"
        case .privacy: return "lock.shield.fill"
        case .userManual: return "book.fill"
        }
    }
}

class SettingsViewController: BaseVC {
    
    @IBOutlet weak var bannerView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    init() {
        super.init(nibName: "SettingsViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private let settingItems: [[SettingItem]] = [
        [.share, .rate],
        [.contact, .privacy, .userManual]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    private func setupUI() {
        view.backgroundColor = .appBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Setup banner view with rounded corners and shadow
        bannerView.layer.cornerRadius = 16
        bannerView.clipsToBounds = true
        
        // Add shadow to the superview layer (so shadow is visible outside the clipped bounds)
        if let containerView = bannerView.superview {
            containerView.layer.shadowColor = UIColor.black.cgColor
            containerView.layer.shadowOpacity = 0.1
            containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            containerView.layer.shadowRadius = 8
            containerView.layer.masksToBounds = false
            
            // Set shadow path for better performance
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let shadowPath = UIBezierPath(roundedRect: self.bannerView.frame, cornerRadius: 16)
                containerView.layer.shadowPath = shadowPath.cgPath
            }
        }
        
        let ges = UITapGestureRecognizer(target: self, action: #selector(bannerViewTapped))
        bannerView.addGestureRecognizer(ges)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingTableViewCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 60
    }
    
    @objc private func bannerViewTapped() {
        self.tabBarController?.selectedIndex = 0
    }
    
    
    private func handleSettingItem(_ item: SettingItem) {
        switch item {
            
        case .share:
            showShareApp()
        case .rate:
            Tips.openRate()
        case .contact:
            EmailSender.send(from: self)
        case .privacy:
            showWebPage(.policy)
        case .userManual:
            showWebPage(.terms)
        }
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingItems.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingItems[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingTableViewCell
        let item = settingItems[indexPath.section][indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = settingItems[indexPath.section][indexPath.row]
        handleSettingItem(item)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}

class SettingTableViewCell: UITableViewCell {
    
    private let containerView = UIView()
    private let iconBackgroundView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let arrowImageView = UIImageView()
    
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
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        iconBackgroundView.backgroundColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 0.1)
        iconBackgroundView.layer.cornerRadius = 8
        iconBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconBackgroundView)
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconBackgroundView.addSubview(iconImageView)
        
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            iconBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            iconBackgroundView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconBackgroundView.widthAnchor.constraint(equalToConstant: 40),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: 40),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconBackgroundView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconBackgroundView.trailingAnchor, constant: 15),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            arrowImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            arrowImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with item: SettingItem) {
        iconImageView.image = UIImage(systemName: item.icon)
        titleLabel.text = item.title
    }
}

