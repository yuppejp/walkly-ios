//
//  Util.swift
//  Walkly
//
//  Created on 2022/10/10.
//  
//

import Foundation

extension Double {
    func toDecimalString(_ minDigits: Int = 0, _ maxDigits: Int = 0) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = minDigits
        f.maximumFractionDigits = maxDigits
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    func toIntegerString() -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    func toPercentString(minDigits: Int = 0, maxDigits: Int = 0, percentSymbol: String? = nil) -> String {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.minimumFractionDigits = minDigits
        f.maximumFractionDigits = maxDigits
        f.percentSymbol = percentSymbol
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }

//    var toColor: Color {
//        if self == 0 {
//            return Color.primary
//        } else if self > 0 {
//            let green = Color.green // Color(red: 96/255, green: 189/255, blue: 113/255)
//            return green
//        } else {
//            let red = Color.red // Color(red: 231/255, green: 101/255, blue: 100/255)
//            return red
//        }
//    }
}

extension Date {
    func toString(_ dateFormat: String = "yyyy/MM/dd HH:mm:ss") -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "ja_JP")
        f.timeZone = TimeZone(identifier:  "Asia/Tokyo")
        f.dateFormat = dateFormat
        let dateString = f.string(from: self)
        return dateString
    }
}
