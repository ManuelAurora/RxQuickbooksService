import Foundation

extension Date
{
    var calendar: Calendar { return Calendar.current }
    var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }
    
    var beginningOfMonth: Date? {
        let startOfDay = calendar.startOfDay(for: self)    
        let components = calendar.dateComponents([.year, .month], from: startOfDay)
        let startOfMonth = calendar.date(from: components)
        
        return startOfMonth
    }
    
    var endOfMonth: Date? {
        
        if let date = beginningOfMonth, let range = calendar.range(of: .day, in: .month, for: date)
        {
            return calendar.date(byAdding: DateComponents(day: range.upperBound - 1), to: date)
        }
        else { return nil }
    }
    
    private func formattedString() -> String
    {
        let formattedString = dateFormatter.string(from: self)
        
        return formattedString
    }
    
    func stringForSalesForceQuery() -> String {
        
        var df: DateFormatter {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            return f
        }
        
        return df.string(from: self)
    }
    
    func stringForQuickbooksQuery() -> String {
        
        return formattedString()
    }
}
