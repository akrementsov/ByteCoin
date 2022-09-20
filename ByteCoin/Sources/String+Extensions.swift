//
//  String+Extensions.swift
//  ByteCoin
//
//  Created by Andrey on 9/17/22.
//  Images Copyright © 2019 The App Brewery. All rights reserved.
//

import Foundation

extension String {
    func round(_ digit: Int) -> String{
        var count = 0
        var out = ""
        
        for i in self {
            if count < digit {
                if i.isNumber {
                    count += 1
                }
                out += String(i)
            }
        }
        return out
    }
}
