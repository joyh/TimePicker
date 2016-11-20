import UIKit

public class TimePicker: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {
    private let maxRowCount = 24000
    private var wheelMargin: Int { return maxRowCount / 2 }
    private var date: Date!
    public var timeZone = TimeZone.current
    private var calendar: Calendar {
        var _gregCal = Calendar(identifier: .gregorian)
        _gregCal.locale = locale
        _gregCal.timeZone = self.timeZone
        return _gregCal
    }
    public var locale = Locale.autoupdatingCurrent {
        didSet {
            refreshTimeFormat()
            reloadAllComponents()
            setDate(date, animated: false)
        }
    }
    
    private enum TimeFormat {
        enum HourDigit {
            case minOne     // 9
            case minTwo     // 09
        }
        case ampmTrailing(HourDigit)
        case ampmLeading(HourDigit)
        case twentyFourHours(HourDigit)
    }
    
    private var _timeFormat: TimeFormat?
    
    public var timeSelectionHandler: ((Date) -> Void)?
    private var localeChangeObserver: AnyObject!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    private func initialize() {
        dataSource = self
        delegate = self
        setDate(Date(), animated: false)
        localeChangeObserver = NotificationCenter.default.addObserver(forName: NSLocale.currentLocaleDidChangeNotification, object: nil, queue: nil, using: { [weak self] (noti) in
            guard let ss = self else { return }
            ss.refreshTimeFormat()
            ss.reloadAllComponents()
            ss.setDate(ss.date, animated: false)
            })
    }
    
    public func setDate(_ date: Date, animated: Bool) {
        self.date = date
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        selectRow(hour + wheelMargin, inComponent: hmsIndex.hour, animated: animated)
        selectRow(minute + wheelMargin, inComponent: hmsIndex.minute, animated: animated)
        selectRow(second + wheelMargin, inComponent: hmsIndex.second, animated: animated)
    }

    private func refreshTimeFormat() {
        _timeFormat = nil
        let _ = timeFormat
    }
    
    private var timeFormat: TimeFormat {
        if _timeFormat == nil {
            guard let formattedString = DateFormatter.dateFormat(fromTemplate: "jm", options: 0, locale: locale) else {
                _timeFormat = .ampmTrailing(.minOne)
                return _timeFormat!
            }
            if let _ = formattedString.range(of: "H") {
                if let _ = formattedString.range(of: "HH") {
                    _timeFormat = .twentyFourHours(.minTwo)
                }
                else {
                    _timeFormat = .twentyFourHours(.minOne)
                }
            }
            else {
                let hourDigit: TimeFormat.HourDigit
                if let _ = formattedString.range(of: "hh") {
                    hourDigit = .minTwo
                }
                else {
                    hourDigit = .minOne
                }
                if formattedString.hasPrefix("a") {
                    _timeFormat = .ampmLeading(hourDigit)
                }
                else if formattedString.hasSuffix("a") {
                    _timeFormat = .ampmTrailing(hourDigit)
                }
            }
            
        }
        return _timeFormat!
    }
    
    private func twoDigitString(_ someInt: Int) -> String {
        if someInt < 10 && someInt >= 0 {
            return "0\(someInt)"
        }
        return "\(someInt)"
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch timeFormat {
        case .twentyFourHours(_):
            return 3
        default:
            return 4
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch timeFormat {
        case .ampmTrailing(_) where component == 3:
            return 2
        case .ampmLeading(_) where component == 0:
            return 2
        default:
            return maxRowCount
        }
    }

    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 60
    }
    
    private var hmsIndex: (hour: Int, minute: Int, second: Int) {
        switch timeFormat {
        case .twentyFourHours(_), .ampmTrailing(_):
            return (0, 1, 2)
        case .ampmLeading(_):
            return (1, 2, 3)
        }
    }
    
    private var AMPMIndex: Int? {
        switch timeFormat {
        case .ampmTrailing(_):
            return 3
        case .ampmLeading(_):
            return 0
        case .twentyFourHours(_):
            return nil
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let ampmi = AMPMIndex, ampmi == component {
            return row == 0 ? calendar.amSymbol : calendar.pmSymbol
        }
        
        if component == hmsIndex.hour {
            let hour: Int
            switch timeFormat {
            case .twentyFourHours(_):
                hour = row % 24
            default:
                let mod12 = row % 12
                hour = mod12 == 0 ? 12 : mod12
            }
            
            
            
            //Horrible hack for automatic AM/PM setting
            switch timeFormat {
            case .ampmLeading(_), .ampmTrailing(_):
                guard let ampmi = AMPMIndex else { break }
                let twentyFourHour = row % 24
                if twentyFourHour == 16 || twentyFourHour == 19 {
                    selectRow(1, inComponent: ampmi, animated: true)
                }
                else if twentyFourHour == 7 || twentyFourHour == 4 {
                    selectRow(0, inComponent: ampmi, animated: true)
                }
            default:
                break
            }
            
            
            switch timeFormat {
            case .ampmLeading(.minTwo), .ampmTrailing(.minTwo), .twentyFourHours(.minTwo):
                return twoDigitString(hour)
            default:
                return "\(hour)"
            }
        }
        else {
            let zeroTo59 = row % 60
            return twoDigitString(zeroTo59)
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        syncAMPMAndHourComponent()
        let second = pickerView.selectedRow(inComponent: hmsIndex.second) % 60
        let minute = pickerView.selectedRow(inComponent: hmsIndex.minute) % 60
        let hour = pickerView.selectedRow(inComponent: hmsIndex.hour) % 24
        
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        comps.second = second
        guard let newDate = calendar.date(from: comps) else { return }
        self.date = newDate
        self.timeSelectionHandler?(newDate)
    }
    
    private func syncAMPMAndHourComponent() {
        guard let ampmi = AMPMIndex else { return }
        let isAM = self.selectedRow(inComponent: ampmi) == 0
        let selectedRow = self.selectedRow(inComponent: hmsIndex.hour)
        let mod24 = selectedRow % 24
        if isAM {
            if mod24 >= 12 {
                selectRow(selectedRow - 12, inComponent: hmsIndex.hour, animated: false)
            }
        }
        else {
            if mod24 < 12 {
                selectRow(selectedRow + 12, inComponent: hmsIndex.hour, animated: false)
            }
        }
    }
}
