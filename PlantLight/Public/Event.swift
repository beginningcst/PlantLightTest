enum EventTag: String, TextCssHandler {
    
    case feature_tab_home_show = "展示首页"
    case feature_tab_guide_show = "展示帮助页"
    case feature_tab_settings_show = "展示设置页"
    case feature_agreement_show = "展示同意协议页"
    
    case feature_agreement_terms_click = "点击同意协议页条款"
    case feature_agreement_agree_click = "点击同意协议页同意"
    
    case feature_guide_item_click = "点击帮助页子项"
    case feature_home_help = "点击首页帮助"
    case feature_home_help_learn_more = "点击首页更多帮助"
    case feature_home_fl_click = "点击首页灯源FL"
    case feature_home_cmh_click = "点击首页灯源CMH"
    case feature_home_white_light_click = "点击首页白炽灯"
    case feature_home_sunlight_click = "点击首页日照"
   
    var description: String {
        switch self {
        default :
            return ""
        }
    }
}

struct Event {
    static func event(page: EventTag, name: String, parameters: [String: Any]? = nil) {
        HXKit.log.eventTag(module: .page(page), tag: page.rawValue, name: name, parameters: parameters ?? [:])
    }
    
    static func add(_ tag: EventTag, info: [String : Any]? = nil, productId: String? = nil) {
        switch tag {
        case .feature_tab_home_show, .feature_tab_settings_show:
            HXKit.log.pageDidEnter(tag, tag: tag.rawValue, parameters: info ?? [:])
        default:
            Event.event(page: tag, name: tag.description, parameters: info)
        }
    }
}
