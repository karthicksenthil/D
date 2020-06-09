//
//  dataStructure.swift
//  MusicPlayer
//
//  Created by Naveen kumar Oruganti on 29/05/20.
//  Copyright © 2020 Sandeep Athiyarath. All rights reserved.
//

import Foundation
struct MusicDetails: Codable
{
    var title: String
    var singer: String
    var album: String
    var cover: String?
    
    init(title: String, singer: String, album: String, cover: String)
    {
        self.title = title
        self.singer = singer
        self.album = album
        self.cover = cover
    }
}
