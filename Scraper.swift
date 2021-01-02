//
//  Scraper.swift
//  web-scraper-swift
//
//  Created by Rox
//

import Cocoa

class Scraper {

    let session: URLSession
    var dataTask: URLSessionDataTask?
    var dataDownload: URLSessionDownloadTask?
    private var settings: [String:Any]
    var fileManager : FileToMove
    
    let notAllowedKindOfFile = [
        "gosharefile_audio"
    ]
    
    init(settings:[String:Any]) {
        self.settings = settings
        
        self.session = URLSession(configuration: .default)
        
        let settingsFileManager = [
            "folderNameMain" : self.settings["folderName"] as Any,
            "notAllowedFiles": self.settings["notAllowedFiles"] as Any,
            "notAllowedKindOfFile": self.settings["notAllowedKindOfFile"] as Any,
            "skippingFileSizeSets": self.settings["skippingFileSizeSets"] as Any
        ]  as [String : Any]
        
        self.fileManager = FileToMove(settings: settingsFileManager)
        
        print("\nScraper() initialized\n")
    }
    
    private func debug(message: Any){
        
        if self.settings["debug"] as! Bool == true {
            print(message)
        }
        
    }
    
    func runScrapNumber(n:Int) {
        let nHEX = String(format:"%02X", n)
        
        var address = self.settings["addressBased"] as! String
        address = address.replacingOccurrences(of: "###", with: nHEX)
        
        print("Start scraping NUMBER -> \(n) = HEX -> \(nHEX) @ ADDRESS -> \(address)")
        
        var request = self.requestLocation(address: address)
        
        request["number"] = ["n":n,"nHEX":nHEX]
        
        self.debug(message: request)

        if request["status"] as! Int == 200 && request["url"] as? String != "" && self.fileManager.filter(obj: request["fileName"] as! [String : String]) == true{
            
            self.download(obj: request)
            
            //call download and saving func
            print("Done. \n")
        }
        else {
            self.debug(message: "It's NOT...\(String(describing: request["status"]))...")
            print("Skipped. \n")
        }
        
        
        
    }
    
    private func download(obj:[String:Any]){
        self.debug(message: "func DOWNLOAD starting")
        
        dataDownload?.cancel()
        
        let url = URL(string: obj["url"] as! String)
        let semaphore = DispatchSemaphore(value: 0)
        
        self.dataDownload = self.session.downloadTask(with: url!) { (data, response, error) in
            let statusCode = (response as! HTTPURLResponse).statusCode
            self.debug(message: "RESPONSE DOWNLOAD DATA -> \(statusCode)")
            
            
            if statusCode == 200 {
                self.debug(message: "DOWNLOADED DATA ->")
                self.debug(message: data as Any)
                self.debug(message: "TYPE -> \(type(of: data))")
                
                let num = (obj["number"] as? [String:Any])?["n"] as! Int
                
                let subFolder = FileToMove.thousandsRange(inputNumber: num)
                
                self.fileManager.moveFile(objFilename: obj["fileName"] as! [String : String],data: data!, subFolder: String(subFolder))
                
            }
            
            
            semaphore.signal()
        }

        self.dataDownload?.resume()
        semaphore.wait()
    }
    
    private func requestLocation(address:String) -> [String:Any] {
        
        dataTask?.cancel()
        
        let prefix = (settings["prefixs"] as! Array<String>)[0]
        
        let url = URL(string: address)
        let semaphore = DispatchSemaphore(value: 0)

        var result: [String : Any] = [
            "status": false,
            "url": "",
            "fileName": []
        ]
        
        self.dataTask = self.session.dataTask(with: url!) {(data, response, error) in
            let httpResponse = response as! HTTPURLResponse

            self.debug(message: httpResponse)
            self.debug(message:"STATUS -> \(httpResponse.statusCode)")
            self.debug(message:"URL -> \(String(describing: httpResponse.value(forKey: "URL")!))")
            
            let statusCode = httpResponse.statusCode
            let urlExtracted = self.extractor(input: String(describing: httpResponse.value(forKey: "URL")!),prefix: prefix)
            
            
            result["status"] = statusCode
            result["url"] = urlExtracted
            
            if result["status"] as! Int == 200 && urlExtracted != ""{
                let fileName = self.extractFileName(input: urlExtracted)
                
                if fileName.isEmpty {
                    result["status"] = 0
                }else{
                    result["fileName"] = fileName
                }
            }
        
            semaphore.signal()
        }
        
        dataTask?.resume()
        semaphore.wait()
        
        return result
    }
    
    
    private func extractor(input:String,prefix:String) -> String{
        
        var output: String = ""
        
        if input.hasPrefix(prefix){
            
            var subString = input.replacingOccurrences(of: prefix, with: "")
            subString = subString.removingPercentEncoding ?? ""
            subString = subString.components(separatedBy: "&")[0]
            
            output = String(subString)
        }
        
        return output
    }

    private func extractFileName(input:String) -> [String:String]{
        
        let prefixs = settings["prefixs"] as! Array<String>
        
        var inputMan = input
        var output: [String:String] = [:]
        
        self.debug(message: "INPUTMAN BEFORE -> \(inputMan)")
        
        for prefix in prefixs{
            if inputMan.contains(prefix){
                let subString = inputMan.replacingOccurrences(of: prefix, with: "")
                inputMan=(String(subString))
                
                self.debug(message: "INPUTMAN NEW -> \(inputMan)")
            }
            
        }
        
        inputMan = (String(inputMan.components(separatedBy: "&")[0]))
        
        self.debug(message: "INPUTMAN AFTER -> \(inputMan)")
        
        let order = [
            "dateName",
            "type",
            "compressName"
        ]
        
        for (index,subString) in inputMan.components(separatedBy: "/").enumerated(){
            output[order[index]] = String(subString)
        }
        
        //output["ext"] = output["compressName"]!.components(separatedBy: ".")[1] //bug
        
        let pathExtension = URL(string: output["compressName"]!)?.pathExtension
        
        if pathExtension != nil {
            output["ext"] = pathExtension
        }else{
            return [:] // not an identifiable file
        }

        
        return output
    }
    
}
