//
//  SiriQueryAPI.swift
//  Siri-Query-mac
//
//  Created by Cal Stephens on 4/23/17.
//  Copyright © 2017 SiriQuery. All rights reserved.
//

import Foundation

class SiriQueryAPI {
    
    private static let baseURL = URL(string: "http://10.218.0.233:8081")!
    
    static var currentTaskID: String?
    
    
    static func resetServer() {
        dataTask(for: "/reset", completion: { response in
            print("reset server: \(response ?? "none")")
        })
    }
    
    static func recordingAvailable(completion: @escaping (Bool) -> ()) {
        dataTask(for: "/recordingAvailable", completion: { response in
            
            if let response = response {
                if response == "false" { completion(false) }
                else {
                    SiriQueryAPI.currentTaskID = response //save the task id
                    completion(true)
                }
            }
                
                //error
            else {
                completion(false)
            }
        })
    }
    
    static func rawTextForNextQuery(completion: @escaping (String?) -> ()) {
        dataTask(for: "/rawtext", completion: { response in
        
            if let response = response {
                if response == "false" { completion(nil) }
                else {
                    completion(response)
                }
            } else {
                completion(nil)
            }
        })
    }
    
    //uploading is handled by nate's code
    
    static func deliverResponse(imagePath: String, audioPath: String) {
        
        guard let taskId = SiriQueryAPI.currentTaskID else {
            return
        }
        
        let base64s: [String?] = [imagePath, audioPath].map({ path in
            let url = URL(fileURLWithPath: path)
            guard let data = try? Data(contentsOf: url) else {
                print("Cannot load file at \(path)")
                return nil
            }
            
            let base64 = data.base64EncodedData()
            return String(data: base64, encoding: .utf8)!.replacingOccurrences(of: "\n", with: "")
        })
        
        guard let imageData = base64s[0], let audioData = base64s[1] else { return }
        let siriResponse = "{\"image\": \"\(imageData)\", \"audio\": \"\(audioData)\"}"
        
        let bodyJson = "{\"task-id\": \"\(taskId)\", \"siri-response\": \(siriResponse)}"
        
        
        //post the data
        let url = SiriQueryAPI.baseURL.appendingPathComponent("/deliverSiriResponse")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyJson.data(using: .utf8)
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, _, error in
            print(data)
            print(error)
        }).resume()
    }
    
    
    
    //MARK: - Helpers
    
    private static func dataTask(for endpoint: String, completion: @escaping (String?) -> ()) {
        
        let url = SiriQueryAPI.baseURL.appendingPathComponent(endpoint)
        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            
            print(error)
            
            if let data = data, let string = String(data: data, encoding: .utf8) {
                completion(string)
            } else {
                completion(nil)
            }
            
        })
        
        task.resume()
    }
    
}
