//
//  main.swift
//  web-scraper-swift
//
//  Created by Rox
//


import IOKit.pwr_mgt

var noSleepAssertionID: IOPMAssertionID = 0
var noSleepReturn: IOReturn? // Could probably be replaced by a boolean value, for example 'isBlockingSleep', just make sure 'IOPMAssertionRelease' doesn't get called, if 'IOPMAssertionCreateWithName' failed.
func disableScreenSleep(reason: String = "Unknown reason") -> Bool? {
    guard noSleepReturn == nil else { return nil }
    noSleepReturn = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
                                            IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                            reason as CFString,
                                            &noSleepAssertionID)
    return noSleepReturn == kIOReturnSuccess
}
func  enableScreenSleep() -> Bool {
    if noSleepReturn != nil {
        _ = IOPMAssertionRelease(noSleepAssertionID) == kIOReturnSuccess
        noSleepReturn = nil
        return true
    }
    return false
}

disableScreenSleep() //Preventing display sleeping on running


//start
print("\n Hello!")

let settings = [
    "folderName" : "web-image-sms",
    "prefixs" : [
        "http://gosms.gomocdn.com/mms/v14/index.html?u=",
        "http://gosms.gomocdn.com/"
    ],
    "notAllowedFiles" : ["gif","amr","xml"],
    "notAllowedKindOfFile" : [
        "gosharefile_audio"
    ],
    "addressBased": "http://gs.3g.cn/D/###/w",
    "skippingFileSizeSets": [
        "skipLowSizeFile": true,
        "fileSizeLimit" : 23000 //byte
    ],
    "debug": false
    
] as [String : Any]

var scraper = Scraper(settings: settings)

var range = [
    "start": 0,
    "end": 0,
    "increament": 0
]

print("Type START range: ")
range["start"] = Int(readLine()!) ?? 0

print("\nType INCREMENT: ")
range["increament"] = Int(readLine()!) ?? 0

range["end"] = range["start"]! + range["increament"]!

print("\nAll set...now let's go scraping...\n")

for n in range["start"]!...range["end"]!{
    let nHEX = String(format:"%02X", n)
    print("NUMBER -> \(n) = HEX -> \(nHEX)")

    scraper.runScrapNumber(n: n)

}

print("\nFinished for the range set, from \(String(describing: range["start"]!)) to \(String(describing: range["end"]!)), increased by \(String(describing: range["increament"]!)).")

print("\n\n Bye bye! \n\n")
