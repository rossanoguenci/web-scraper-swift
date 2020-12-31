# Go SMS Pro Scraper Demo
![Visitors](https://visitor-badge.vercel.app/p/rossanoguenci-web-scraper-swift)


Following the recent findings (Source: [Trustwave](https://www.trustwave.com/en-us/resources/blogs/spiderlabs-blog/go-sms-pro-vulnerable-to-media-file-theft/?=go-sms-pro-vulnerability-to-media-file-theft)) that the Android messaging app **Go SMS Pro** uploads all content publicly, here is an example of a command line scraper, written in **Swift 5**, to fetch and download images from a URL following an incremental pattern. 

```eg. site.example/000000 > FFFFFF```

## Installation & Dependencies

Download the package and import files in a new Xcode project.

The project needs [ZipFoundation](https://github.com/weichsel/ZIPFoundation) as dependence to extract automatically downloaded archives.

## Usage

Build and run the project, it will ask to set a range of numbers on console. 

It will create a new folder ***web-image-sms*** in your Download folder and it will save downloaded files in thousandth subfolders.

It filters already audio files, gifs, xml and it deletes files lower than 23 kb (90% chance of drawings..)

## Customisation 

In ***main.swift***, you can customise the settings array

```swift

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


```

## Disclaimer

This open source project has been posted for Swift language studying purposes only.

I hope the developers fix the bug and implement some kind of authentication for shared content.

## Contribute

Any contribution to improve this project is welcome. 

[![paypal.me/rossanoguenciuk](https://ionicabizau.github.io/badges/paypal.svg)](https://www.paypal.me/rossanoguenciuk) - If you find this project useful, please offer me a coffee, I love it ☕️ 

## License
![MIT](https://img.shields.io/github/license/rossanoguenci/web-scraper-swift?style=for-the-badge)
