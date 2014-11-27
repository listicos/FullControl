//
//  Date.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 26/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

extension NSDate
{
    convenience
    init(dateString:String, format:String = "yyyy-MM-dd") {
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = format
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        let d = dateStringFormatter.dateFromString(dateString)
        self.init(timeInterval:0, sinceDate:d!)
    }
}