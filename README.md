# TimePicker
UIPickerView subclass, locale aware hour–minute–second time picker for iOS.

## Why?
UIDatePicker does not offer seconds–precision time picking mode. [Metapho](http://metapho.co) needed one to edit date of a photo.

## How to use
Similar to UIDatePicker. `init(frame: CGRect)` gives you an instance with system time zone and locale. However TimePicker is not UIControl subclass. There’s no target action. Instead, `timeSelectionHandler: ((date: Date) -> Void)` is called when time is changed by a user interaction. 

![TimePicker Screenshot](https://raw.githubusercontent.com/joyh/TimePicker/master/hmg-time-picker-screenshot.png)

## Requirement
Swift 3

## License
MIT License. See the license file