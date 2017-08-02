import Foundation
import SwiftyJSON

struct OauthParameters
{
    let consumerKey: String
    let consumerSecret: String
    let requestTokenUrl: String
    let authorizeUrl: String
    let accessTokenUrl:String
    let callbackUrl: String?
    
    init(consumerKey: String,
         consumerSecret: String,
         requestTokenUrl: String,
         authorizeUrl: String,
         accessTokenUrl: String,
         callbackUrl: String? = nil) {
        self.consumerKey     = consumerKey
        self.consumerSecret  = consumerSecret
        self.requestTokenUrl = requestTokenUrl
        self.authorizeUrl    = authorizeUrl
        self.accessTokenUrl  = accessTokenUrl
        self.callbackUrl     = callbackUrl
    }
}

enum QBPredifinedDateRange: String
{
    case today = "Today"
    case yesterday = "Yesterday"
    case thisMonth = "This Month"
    case thisQuarter = "This Fiscal Quarter"
    case thisYear = "This Fiscal Year"
}

enum QBPredifinedSummarizeValues: String
{
    case days = "Days"
    case month = "Month"
    case customers = "Customers"
}

enum QBQueryParameterKeys: String
{
    case dateMacro = "date_macro"
    case startDate = "start_date" // yyyy-MM-dd
    case endDate   = "end_date"
    case summarizeBy = "summarize_column_by"
    case query = "query"
}

struct ExternalKpiInfo
{
    var kpiName: String = ""
    var kpiValue: String = ""
}

enum QBConstants
{
    static let lenghtOfRealmId = 15
}



