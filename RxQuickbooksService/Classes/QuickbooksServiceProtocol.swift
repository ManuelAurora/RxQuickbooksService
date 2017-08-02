import Foundation
import RxSwift
import SwiftyJSON
import OAuthSwift

protocol QuickbooksServiceProtocol
{
    func authorize(application: UIApplication, _ handler: OAuthSwiftURLHandlerType) -> Observable<AuthorizationResponse>
    func getInvoices(with condition: QBQueryRequest.Condition?) -> Observable<[Invoice]>
    func getBills(with condition: QBQueryRequest.Condition?) -> Observable<[Bill]>
    func getPurchases(with condition: QBQueryRequest.Condition?) -> Observable<[Purchase]>
    func getReport(_ report: QBReportRequest) -> Observable<QuickbooksReport>
    func query(_ query: QBQueryRequest) -> Observable<JSON>
}

//MARK: Misc
struct AuthorizationResponse
{
    let token:        String
    let realmId:      String
    let tokenSecret:  String
}
