import UIKit
import PlaygroundSupport

//Locale aware hour: minute: second picker
//run timeSelectionHandler when user selects time
/*
 TODO:
    - UIDatePicker like landscape orientation support
    - Non gregorian calendar support
*/

class TimePickerTestViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white()
        
        
        //default locale == system locale
        let timePicker = TimePicker(frame: .zero)
        view.addSubview(timePicker)
        timePicker.timeSelectionHandler = { (date) in
            print(DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium))
        }
        
        //Korean locale: AM/PM goes first
        let timePickerKoKR = TimePicker(frame: .zero)
        timePickerKoKR.frame.origin.y += 200
        timePickerKoKR.locale = Locale(localeIdentifier: "ko-KR")
        view.addSubview(timePickerKoKR)
        
        
        //UK locale: 24hours
        let timePickerUK = TimePicker(frame: .zero)
        timePickerUK.frame.origin.y += 400
        timePickerUK.locale = Locale(localeIdentifier: "en-UK")
        view.addSubview(timePickerUK)
    }
}

let vc = TimePickerTestViewController()
PlaygroundPage.current.liveView = vc
