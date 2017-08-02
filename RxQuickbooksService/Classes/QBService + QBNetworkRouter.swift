import Alamofire
import Foundation
import RxSwift
import RxAlamofire
import OAuthSwift
import OAuthSwiftAlamofire
import SwiftyJSON

extension QBService
{
    enum NetworkRouter
    {
        fileprivate static let baseUrl = "https://quickbooks.api.intuit.com/v3/company/"
        fileprivate static let sandboxUrl = "https://sandbox-quickbooks.api.intuit.com/v3/company/"
        fileprivate static let bag = DisposeBag()
        case authorization(handler: OAuthSwiftURLHandlerType)
        case query(QBQueryRequest)
        case report(QBReportRequest)
        
        static private(set) var oauthswiftParameters: OauthParameters!
        
        private static var sessionManager: SessionManager = {
            let sm = SessionManager()
            sm.adapter = oauthswift.requestAdapter
            return sm
        }()
        
        static var oauthswift: OAuth1Swift = {
            let oauthswift = OAuth1Swift(
                consumerKey:     oauthswiftParameters.consumerKey,
                consumerSecret:  oauthswiftParameters.consumerSecret,
                requestTokenUrl: oauthswiftParameters.requestTokenUrl,
                authorizeUrl:    oauthswiftParameters.authorizeUrl,
                accessTokenUrl:  oauthswiftParameters.accessTokenUrl
            )
            return oauthswift
        }()
        
        static var realmId: String?
        
        private var pathComponent: String {
            switch self
            {
            case .report(let report):   return "reports/\(report.stringRepresentation())"
            case .query:                return "query"           
            case .authorization:        return ""
            }
        }
        
        private var parameters: Parameters {
            var parametersToReturn = Parameters()
            switch self
            {
            case .authorization: break
            case .query(let queryString): parametersToReturn["query"] = queryString.stringRepresentation()
            case .report(let reportRequest): parametersToReturn["date_macro"] = reportRequest.periodStringRepresentation()
            }
            return parametersToReturn
        }
        
        private var headers: HTTPHeaders {
            return ["Accept":"application/json"]
        }
        
        static func set(oauthParameters: OauthParameters) {
            oauthswiftParameters = oauthParameters
        }
        
        func makeRequest() -> Observable<JSON> {
            guard var mutableUrl = URL(string: NetworkRouter.baseUrl) else {
                fatalError("Unable to create url")
            }
            
            if let realmId = NetworkRouter.realmId
            {
                mutableUrl.appendPathComponent(realmId)
            }
            
            mutableUrl.appendPathComponent(pathComponent)
            
            switch self
            {
            case .authorization(let handler):
                let oauthswift = NetworkRouter.oauthswift
                oauthswift.authorizeURLHandler = handler
                
                guard let callbackUrl = NetworkRouter.oauthswiftParameters.callbackUrl else {
                    fatalError("There is no callback url")
                }
                
                return oauthswift.rx_authorize(withCallbackURL: callbackUrl)
                    .map { _, _, parameters in
                        JSON(parameters)
                }
                
            case .query:
                guard let _ = NetworkRouter.realmId else { fatalError("No realm Id found") }                
                
            case .report:
                guard let _ = NetworkRouter.realmId else { fatalError("No realm Id found") }
            }
            
            let requestObservable = NetworkRouter.sessionManager.rx.responseJSON(.get,
                                                                                   mutableUrl,
                                                                                   parameters: parameters,
                                                                                   headers: headers)
            return requestObservable.map { return JSON(object: $0.1) }
        }
    }
}
