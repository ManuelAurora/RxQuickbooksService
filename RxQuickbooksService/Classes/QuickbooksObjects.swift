import Foundation
import SwiftyJSON

fileprivate let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd"
    return df
}()

fileprivate let prettyFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "dd/MM/yyyy"
    return df
}()

//MARK: Quickbooks Requests Objects
struct QBQueryRequest
{
    enum Condition
    {
        case txnDate(start: Date, end: Date)
        
        func queryString() -> String {
            switch self
            {
            case .txnDate(let start, let end):
                return "TxnDate >= \(start.stringForQuickbooksQuery()) AND TxnDate <=  \(end.stringForQuickbooksQuery())"
            }
        }
    }
    
    enum Object: String
    {
        case invoice  = "Invoice"
        case bill     = "Bill"
        case purchase = "Purchase"
    }
    
    private let object: Object
    private let condition: Condition?
    
    init(object: Object, condition: Condition? = nil) {
        self.object    = object
        self.condition = condition
    }
    
    func stringRepresentation() -> String {
        var base = "SELECT * FROM \(object)"
        
        if let condition = condition
        {
            base.append(" WHERE \(condition.queryString())")
        }
        return base
    }
}

struct QBReportRequest
{
    enum ReportType: String
    {
        case balanceSheet = "BalanceSheet"
        case accountList = "AccountList"
        case customerIncome = "CustomerIncome"
        case vendorExpenses = "VendorExpenses"
        case profitAndLoss = "ProfitAndLoss"
    }
    
    private let type: ReportType
    private let period: QBPredifinedDateRange
    
    init(type: ReportType, period: QBPredifinedDateRange) {
        self.type = type
        self.period = period
    }
    
    func periodStringRepresentation() -> String {
        return period.rawValue
    }
    
    func stringRepresentation() -> String {
        return type.rawValue
    }
}

//MARK: Quickbooks Response Objects
protocol QBObjectType
{
    var totalAmt: Float { get }
    var txnDate: Date { get }
    var txnDateString: String { get }
    var dueDateString: String? { get }
    var prettyDateString: String { get }
    var dueDate: Date? { get }
    init(json: JSON)
}

struct Invoice: QBObjectType
{
    let id: Int
    let balance: Float
    let totalAmt: Float
    let docNumber: String
    let customerName: String
    let dueDate: Date?
    let txnDate: Date
    let dueDateString: String?
    let txnDateString: String
    let prettyDateString: String
    
    init(json: JSON) {
        id           = json["Id"].intValue
        balance      = json["Balance"].floatValue
        totalAmt     = json["TotalAmt"].floatValue
        docNumber    = json["DocNumber"].stringValue
        customerName = json["CustomerRef"]["name"].stringValue
        
        let dueDateString = json["DueDate"].stringValue
        let txnDateString = json["TxnDate"].stringValue
        
        self.dueDateString = dueDateString
        self.txnDateString = txnDateString
        
        dueDate = dateFormatter.date(from: dueDateString)!
        txnDate = dateFormatter.date(from: txnDateString)!
        prettyDateString = prettyFormatter.string(from: txnDate)
    }
}

struct Purchase: QBObjectType
{
    var dueDate: Date? = nil
    let txnDateString: String
    let txnDate: Date
    let totalAmt: Float
    let id: Int
    let prettyDateString: String
    let dueDateString: String? = nil
    
    init(json: JSON) {
        id               = json["Id"].intValue
        txnDateString    = json["TxnDate"].stringValue
        totalAmt         = json["TotalAmt"].floatValue
        txnDate          = dateFormatter.date(from: txnDateString)!
        prettyDateString = prettyFormatter.string(from: txnDate)
    }
}

struct Bill: QBObjectType
{
    var dueDateString: String?
    var dueDate: Date?
    let txnDateString: String
    let txnDate: Date
    let totalAmt: Float
    let id: Int
    let prettyDateString: String
    
    init(json: JSON) {
        id            = json["Id"].intValue
        txnDateString = json["TxnDate"].stringValue
        totalAmt      = json["TotalAmt"].floatValue
        txnDate       = dateFormatter.date(from: txnDateString)!
        prettyDateString = prettyFormatter.string(from: txnDate)
        dueDate = nil
        dueDateString = nil
    }
}

struct QuickbooksReport
{
    let name: String
    let startPeriod: String
    let endPeriod: String
    let columns: [Column]
    let rows: [Row]
    var titleValueDict = [String: String]()
    
    init(json: JSON) {
        name        = json["Header"]["ReportName"].stringValue
        startPeriod = json["Header"]["StartPeriod"].stringValue
        endPeriod   = json["Header"]["EndPeriod"].stringValue
        
        let columns = json["Columns"]["Column"].arrayValue.map(Column.init)
        let rows    = json["Rows"]["Row"].arrayValue.map(Row.init)
        
        self.rows    = rows
        self.columns = columns
        
        fillValueDict(rows)
    }
    
    //Recursively filling titleValue dictionary
    private mutating func fillValueDict(_ rows: [Row]) {
        for row in rows
        {
            if row.subrows != nil
            {
                titleValueDict += row.titleValueDict
                fillValueDict(row.subrows!)
            }
            else { break }
        }
    }    
}

extension QuickbooksReport
{
    //Column
    struct Column
    {
        let title: String
        let type: String
        
        init(json: JSON) {
            title = json["ColTitle"].stringValue
            type = json ["ColType"].stringValue
        }
    }
    
    //Row
    struct Row
    {
        enum RowType: String
        {
            case section = "Section"
            case data    = "Data"
        }
        
        let rowType: RowType
        let columnData: [String]
        let subrows: [Row]?
        let header: String
        var titleValueDict = [String: String]()
        
        init(json: JSON) {
            rowType = RowType(rawValue: json["type"].stringValue)!
            
            //Setuping Column data
            let summaryColData = json["Summary"]["ColData"].arrayValue
            var summaryColumnData = [String]()
            summaryColData.forEach {
                var dataString = "\($0["value"].stringValue)"
                if let id = $0["id"].string { dataString += "id: \(id)" }
                summaryColumnData.append(dataString)
            }
            self.columnData = summaryColumnData
            
            if summaryColumnData.count == 2
            {
                let columnTitle = columnData[0]
                titleValueDict[columnTitle] = columnData[1]
            }
            
            //Setuping Header
            let headerColData = json["Header"]["ColData"].arrayValue
            var headerColumnData = [String]()
            headerColData.forEach {
                headerColumnData.append($0["value"].stringValue)
            }
            header = headerColumnData.joined(separator: " ")
            
            var subrows: [Row]?
            
            //Setuping Subrows
            if let rows = json["Rows"]["Row"].array
            {
                subrows = rows.map(Row.init)
            }
            self.subrows = subrows
        }
    }
}
