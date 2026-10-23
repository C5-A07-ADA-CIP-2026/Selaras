//
//  String.swift
//  Selaras
//
//  Created by Dina on 22/10/26.
//


import Foundation

extension String {
    //true kalo ada karakter
    var tidakKosong: Bool {
        !trimmingCharacters(in: .whitespaces).isEmpty
    }
}
