//
//  fileToDownload.swift
//  web-scraper-swift
//
//  Created by Rox
//

import Cocoa
import ZIPFoundation

class FileToMove{
    
    let fileManager : FileManager
    let folderMainURL : URL
    private var settings : [String:Any]
    
    
    init(settings:[String:Any]) {
        
        self.settings = settings
        
        self.fileManager = FileManager.default
        
        self.folderMainURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0].appendingPathComponent(self.settings["folderNameMain"]! as! String)
        
        
        if !self.createMainDir(){
            exit(0)
        }
    }
    
    private func debug(message: Any){
        
        if self.settings["debug"] as? Bool == true {
            print(message)
        }
        
    }
    
    private func createMainDir() -> Bool{
        
        var isDir:ObjCBool = true
        
        if !self.fileManager.fileExists(atPath: self.folderMainURL.path, isDirectory: &isDir){
            
            do {
                try self.fileManager.createDirectory(atPath: self.folderMainURL.path, withIntermediateDirectories: true, attributes: nil)
                
                self.debug(message: "New folder should be created")
                
                return true
            }
            catch {
                print("ERROR: Could not create folder")
                return false
            }
            
        }
        
        self.debug(message: "Main folder already exists!")
        return true
        
    }
    
    private func checkDir(path:String){
        
        var isDir:ObjCBool = true
        
        if !self.fileManager.fileExists(atPath: path, isDirectory: &isDir){
            
            do {
                try self.fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                self.debug(message: "New subfolder should be created")
            }
            catch {
                print("ERROR: Could not create folder")
                exit(0)
            }
            
        }

    }
    
    static func thousandsRange(inputNumber:Int) -> Int{

        let dividedNumber: Float = Float(inputNumber) / 1000.0
        
        let outputNumber: Int = Int(dividedNumber.rounded(.down) * 1000)
    
        return outputNumber
    }

    
    func moveFile(objFilename:[String:String], data:URL, subFolder: String){
        
        var pathToSave = self.folderMainURL.appendingPathComponent(subFolder)
        
        self.checkDir(path: pathToSave.path)
        
        //Single file
        
        let fileName = objFilename["dateName"]!+"_"+objFilename["compressName"]!;
        
        pathToSave = pathToSave.appendingPathComponent(fileName)
        
        if self.fileManager.fileExists(atPath: pathToSave.path){
            
            self.debug(message: "File already exists!")
            
            return
            
        }


        do {
            
            if self.filterSize(item: data) == true{
                try self.fileManager.trashItem(at: data, resultingItemURL: nil)
                self.debug(message: "File low size -> deleted.")
            }else{
            
                self.debug(message: "Trying to save to -> \(pathToSave)")

                try self.fileManager.moveItem(at: data, to: pathToSave)
                
                print("Saved.")
            }
        }
        catch let error as NSError {
            print("ERROR: Not saved -> \(error)")
        }
        
        
        //check if ZIP file
        
        if objFilename["ext"] == "zip"{
            
            self.debug(message: "IT'S A ZIP!")
            
            self.unZip(item: pathToSave)
            
        }
        
    }
    
    func filter(obj:[String:String]) -> Bool{
        
        let notAllowedEXT = settings["notAllowedFiles"] as! Array<String>
        let notAllowedKindOfFile = settings["notAllowedKindOfFile"] as! Array<String>
        
        if notAllowedEXT.contains(obj["ext"]!) || notAllowedKindOfFile.contains(obj["type"]!) {
            self.debug(message: "Skipped by filter()")
            return false
        }
        
        return true //true -> all ok, can pass / false -> no thanks
    }
    
    private func filterSize(item: URL) -> Bool{
        
        let skip = (self.settings["skippingFileSizeSets"] as! [String:Any])["skipLowSizeFile"] as! Bool
        
        if(skip == false){return false}//always pass
        
        let fileSizeLimit = (self.settings["skippingFileSizeSets"] as! [String:Any])["fileSizeLimit"] as! Int
        
        self.debug(message: "Debug settings: skip -> \(skip) - fileSizeLimit: -> \(fileSizeLimit)")
        
        do{
        
            let fileAttributes = try self.fileManager.attributesOfItem(atPath: item.path)
            let fileSize = (fileAttributes[FileAttributeKey.size] as! NSNumber).uint64Value
            
            self.debug(message: "File: \(item) - Size: \(fileSize)")
            
            self.debug(message: "FileType: \(type(of: fileSize)) - Size: \(String(describing: fileSize))")
            
            if fileSize < (fileSizeLimit as NSNumber).uint64Value{
                
                self.debug(message: "Filesize: \(fileSize) > Size: \((fileSizeLimit as NSNumber).uint64Value)")
                
                return true //limit!
            }
            
        }catch{
            print("ERROR: Can't get attribute for some reasons.. -> \(error)")
        }
        
        return false //pass
    }
    
    func unZip(item : URL){
        self.debug(message: "it should be a ZIP file -> \(item)")
        
        
        do {
            
            let path = item.deletingLastPathComponent()
            let prefix = item.lastPathComponent.components(separatedBy: "_")[0]
            
            self.debug(message: "\n PATH: \(path)")
            self.debug(message: "PREFIX: \(prefix)")
            
            guard let archive = Archive(url: item, accessMode: .read) else  {
                return
            }
            
            for zippedItem in archive {
                
                self.debug(message: "\n")
                self.debug(message: "zippedItem.path -> \(zippedItem.path)")
                self.debug(message: "type -> \(type(of: zippedItem.path))")
                
                let pathExtension = URL(string: zippedItem.path)?.pathExtension
                
                if pathExtension == nil {
                    continue
                }
                
                let zipOBJ = [
                    "ext": pathExtension!,
                    "type" : ""
                ]
                
                if self.filter(obj: zipOBJ) == false{
                    continue
                }
                
                let finalFilename = prefix+"_"+zippedItem.path
                let urlItemToExtract = path.appendingPathComponent(finalFilename)
                
                self.debug(message: "FinalFileName = \(finalFilename)")
                
                if self.fileManager.fileExists(atPath: urlItemToExtract.path){
                    
                    self.debug(message: "File already exists!")
                    
                    continue
                    
                }
                
                do {
                    
                    try archive.extract(zippedItem, to: urlItemToExtract)
                    
                    if self.filterSize(item: urlItemToExtract) == true{
                        try self.fileManager.trashItem(at: urlItemToExtract, resultingItemURL: nil)
                        self.debug(message: "File low size -> deleted.")
                    }
                    
                } catch {
                    print("ERROR: Extracting entry from archive failed with error -> \(error)")
                    exit(0)
                }
            }
        
            try fileManager.trashItem(at: item, resultingItemURL: nil)
            
        } catch {
            print("ERROR: failed to read directory – bad permissions, perhaps?")
        }
        
    }
    
    func testUnZip(opt:[String:String]){
        //content of folder
        let path = self.folderMainURL.appendingPathComponent(opt["dirToTest"]!)

        do {
            let items = try self.fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)

            for item in items {
                print("Found \(item)")
                
                if item.pathExtension == "zip" {
                
                    print("\n \nIt's a ZIP file!")
                    
                    let prefix = item.lastPathComponent.components(separatedBy: "_")[0]
                    
                    
                    guard let archive = Archive(url: item, accessMode: .read) else  {
                        return
                    }
                    
                    for zippedItem in archive {
                        print("\n")
                        print(zippedItem.path)
                        
                        
                        let finalFilename = prefix+"_"+zippedItem.path
                        
                        print("\n")
                        print("FinalFileName = \(finalFilename)")
                        
                        
                        do {
                            try archive.extract(zippedItem, to: path.appendingPathComponent(finalFilename))
                        } catch {
                            print("Extracting entry from archive failed with error:\(error)")
                            exit(0)
                        }
                    }
                
                    try fileManager.trashItem(at: item, resultingItemURL: nil)
                    
                }else{
                    print("\n\nNot a Zip file...")
                }
                
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print("failed to read directory – bad permissions, perhaps?")
        }
        
    }
    
}
