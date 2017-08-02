import Foundation
import OAuthSwift
import RxSwift
import SwiftyJSON
import RxCocoa

class QBService: QuickbooksServiceProtocol
{
    fileprivate let bag = DisposeBag()
    
    convenience init(oauthParameters: OauthParameters) {
        self.init()
        NetworkRouter.set(oauthParameters: oauthParameters)
    }
    
    func query(_ query: QBQueryRequest) -> Observable<JSON> {
        return NetworkRouter.query(query).makeRequest()
    }
    
    func getReport(_ report: QBReportRequest) -> Observable<QuickbooksReport> {
        return NetworkRouter.report(report).makeRequest().map(QuickbooksReport.init)
    }
    
    func getBills(with condition: QBQueryRequest.Condition? = nil) -> Observable<[Bill]> {
        let billRequest = QBQueryRequest(object: .bill, condition: condition)
        return query(billRequest)
            .map { json in
                return json["QueryResponse"]["Bill"].array ?? []
            }.map {
                $0.map(Bill.init)
            }
    }
    
    func getInvoices(with condition: QBQueryRequest.Condition? = nil) -> Observable<[Invoice]> {
        let invoiceRequest = QBQueryRequest(object: .invoice, condition: condition)
        return query(invoiceRequest)
            .map { json in
                return json["QueryResponse"]["Invoice"].array ?? []
            }.map {
                $0.map(Invoice.init)
        }
    }
    
    func getPurchases(with condition: QBQueryRequest.Condition? = nil) -> Observable<[Purchase]> {
        let purchaseRequest = QBQueryRequest(object: .purchase, condition: condition)
        return query(purchaseRequest)
            .map { json in
                return json["QueryResponse"]["Purchase"].array ?? []
            }.map {
                $0.map(Purchase.init)
        }
    }
    
    func authorize(application: UIApplication, _ handler: OAuthSwiftURLHandlerType) -> Observable<AuthorizationResponse> {
        //Catching Realm ID from callback url.
        //Realm Id is binded to companyIdObservable property.
        //*Takes only onae then completes
        let realmIdObservable = application.rx.realmIdObservable
        
        //Catching token and secret
        let authObservable = NetworkRouter.authorization(handler: handler).makeRequest()
            .map { json -> (token: String, secret: String) in
                let token = json["oauth_token"].stringValue
                let secret = json["oauth_token_secret"].stringValue
                return (token: token, secret: secret)
            }
        
        //Combining Token, Secret and Realm Id.
        let combined = Observable.zip(realmIdObservable, authObservable) {
            (realmId, tokenInfoTuple) -> AuthorizationResponse in
            let info = AuthorizationResponse(token: tokenInfoTuple.token,
                                             realmId: realmId,
                                             tokenSecret: tokenInfoTuple.secret)
            return info
        }
        return combined
    }
}

//MARK: Utility functions
extension QBService
{
    func set(realmId: String, token: String, secret: String) {
        NetworkRouter.oauthswift.client.credential.oauthToken = token
        NetworkRouter.oauthswift.client.credential.oauthTokenSecret = secret
        NetworkRouter.realmId = realmId
    }

    fileprivate func findRealmId(in url: URL) -> String? {
        let parameters = url.absoluteString.removingPercentEncoding?.components(separatedBy: "&")
        
        if let resultArray = parameters?.filter({ $0.contains("realmId")})
        {
            if resultArray.count > 0
            {
                let realmIdString = resultArray[0]
                let index = realmIdString.index(realmIdString.startIndex, offsetBy: 8)
                let realmId = realmIdString.substring(from: index)
                return realmId
            }
        }
        return nil
    }
}


class RxUIApplicationDelegateProxy: DelegateProxy, UIApplicationDelegate, DelegateProxyType
{
    static func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        let application = object as! UIApplication
        return application.delegate
    }
    
    static func setCurrentDelegate(_ delegate: AnyObject?, toObject object: AnyObject) {
        let application = object as! UIApplication
        application.delegate = delegate as? UIApplicationDelegate
    }
    
    
}

extension Reactive where Base: UIApplication {
    var delegate: DelegateProxy {
        return RxUIApplicationDelegateProxy.proxyForObject(base)
    }
    
    var realmIdObservable: Observable<String> {
        return delegate.rx.methodInvoked(#selector(UIApplicationDelegate.application(_:open:options:)))
            .map { parameters in
                parameters[1] as! URL
            }
            .map { self.findRealmId(in: $0) }
            .filter { $0 != nil }
            .map { $0! }
            .take(1)
    }
    
    fileprivate func findRealmId(in url: URL) -> String? {
        let parameters = url.absoluteString.removingPercentEncoding?.components(separatedBy: "&")
        
        if let resultArray = parameters?.filter({ $0.contains("realmId")})
        {
            if resultArray.count > 0
            {
                let realmIdString = resultArray[0]
                let index = realmIdString.index(realmIdString.startIndex, offsetBy: 8)
                let realmId = realmIdString.substring(from: index)
                return realmId
            }
        }
        return nil
    }
}
