
import Foundation

public extension String {
    var initials: String {
        components(separatedBy: " ")
            .filter { !$0.isEmpty }
            .reduce("") { ($0.isEmpty ? "" : "\($0.first!)") + "\($1.first!)" }
            .uppercased()
    }
    
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

    var localized: String {
        let stringToReturn = NSLocalizedString(self, comment: "")
//        guard stringToReturn != self else {
//            return "Missing key"
//        }
//        guard !stringToReturn.isEmpty else {
//            return "No Translation"
//        }
        return stringToReturn
    }
    
    static func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map { _ in letters.randomElement()! })
    }
}

public extension String {
    static func dateAwareTimestamp(for date: Date, calendar: Calendar = .current) -> String {
        var style = Date.FormatStyle(calendar: calendar).hour().minute()
        if !calendar.isDateInToday(date) {
            style = style.month(.twoDigits).day(.twoDigits)
            if !calendar.isDate(Date(), equalTo: date, toGranularity: .year) {
                style = style.year()
            }
        }
        return date.formatted(style)
    }

    static func dayDescription(for date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        var style = Date.FormatStyle(calendar: calendar).month(.abbreviated).day()
        if !calendar.isDate(Date(), equalTo: date, toGranularity: .year) {
            style = style.year()
        }
        return date.formatted(style)
    }

    static func duration(from seconds: Int) -> String {
        [seconds/3600, (seconds%3600)/60, (seconds%3600)%60]
            .map({ String(format: "%02d", $0) })
            .joined(separator: ":")
            .deletingPrefix("00:")
    }
}

// Recognition
public extension String {
    enum RecognitionType {
        case link
        case email
        case phoneNumber
        case address
        
        var checkingType: NSTextCheckingResult.CheckingType? {
            switch self {
            case .link: return .link
            case .address: return .address
            case .phoneNumber: return .phoneNumber
            case .email: return nil
            }
        }
    }
    
    func getRecognisedStringsAndRanges(of types: [RecognitionType]) -> [RecognitionType: [(String, NSRange)]] {
        var returnArray: [RecognitionType: [(String, NSRange)]] = [:]
        for type in types {
            if let checkingType = type.checkingType {
                let stringsAndRanges = getSubstrings(of: checkingType)
                if !stringsAndRanges.isEmpty {
                    returnArray[type] = stringsAndRanges
                }
            } else {
                switch type {
                case .email:
                    let emails = getEmails()
                    if !emails.isEmpty {
                        returnArray[type] = emails
                    }
                default:  break
                }
            }
        }
        return returnArray
    }
    
    private func getEmails() -> [(String, NSRange)] {
        let regex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", options: NSRegularExpression.Options.caseInsensitive)
        //matches will store the all range objects in form of NSTextCheckingResult
        guard let matches = regex?.matches(in: self, options: [], range: NSMakeRange(0, self.count)), !matches.isEmpty else { return [] }
        return matches.compactMap({ ((self as NSString).substring(with: $0.range) as String, $0.range) })
    }
    
    private func getSubstrings(of type: NSTextCheckingResult.CheckingType) -> [(String, NSRange)] {
        let detector = try? NSDataDetector(types: type.rawValue)
        let textRange = NSRange(location: 0, length: self.count)
        let matches = detector?.matches(in: self, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: textRange)
        var returnArray = [(String, NSRange)]()
        for match in matches ?? [] {
            if let linkText = match.url?.absoluteString {
                returnArray.append((linkText, match.range))
            } else if let phoneNumber = match.phoneNumber {
                returnArray.append((phoneNumber, match.range))
            } else if match.addressComponents != nil {
                returnArray.append(((self as NSString).substring(with: match.range) as String, match.range))
            }
        }
        return returnArray
    }
}
