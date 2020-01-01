//
//  Client.swift
//  Iterate
//
//  Created by Michael Singleton on 12/30/19.
//  Copyright © 2019 Pickaxe LLC. (DBA Iterate). All rights reserved.
//

import Foundation

/// Iterate API Client
struct APIClient {
    // MARK: Properties

    /// API Host, should be https://iteratehq.com/api/v1 under most circumstances
    let apiHost: String
    
    /// API Key, you can find this in your Iterate dashboard
    let apiKey: String
    
    /// JSON Encoder
    let encoder = JSONEncoder()
    
    /// JSON Decoder
    let decoder = JSONDecoder()
    
    // MARK: Initializers
    
    /// Initializer
    /// - Parameters:
    ///   - apiKey: Iterate API key
    ///   - apiHost: API Host
    init(apiKey: String, apiHost: String = "https://iteratehq.com/api/v1") {
        self.apiHost = apiHost
        self.apiKey = apiKey
        
        // Default to snake case
        encoder.keyEncodingStrategy = .convertToSnakeCase
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: Request Methods (GET, POST, etc)
    
    /// Make a post request with the provided data and return the results
    /// - Parameters:
    ///   - path: Path to call
    ///   - data: Post body data
    ///   - complete: Results callback
    func post<T: Codable> (path: Path, data: Data, complete: @escaping (T?, Error?) -> Void) {
        guard var request = request(path: Paths.Surveys.Embed) else {
            complete(nil, IterateError.invalidAPIUrl)
            return
        }
        
        request.httpMethod = "POST"
        request.httpBody = data
        
        dataTask(request: request, complete: complete)
    }
    
    // MARK: Helpers
    
    /// Generate a URLRequest set with the proper content type and authentication
    /// - Parameter path: API Path to request
    func request(path: Path) -> URLRequest? {
        guard let url = URL(string: "\(apiHost)\(path)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/javascript", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    /// Create a data task from the request, run the task, handle any errors from the API and return the results
    /// - Parameters:
    ///   - request: Request to run, see the request helper method to help construct it
    ///   - complete: Results callback
    func dataTask<T: Codable>(request: URLRequest, complete: @escaping (T?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                complete(nil, IterateError.apiRequestError)
                return
            }
            
            guard let data = data else {
                complete(nil, IterateError.invalidAPIResponse)
                return
            }
            
            guard let response = try? self.decoder.decode(Response<T>.self, from: data) else {
                complete(nil, IterateError.jsonDecoding)
                return
            }
            
            if let err = response.error {
                complete(nil, IterateError.apiError(err))
                return
            }
            
            complete(response.results, nil)
        }
        
        task.resume()
    }
}