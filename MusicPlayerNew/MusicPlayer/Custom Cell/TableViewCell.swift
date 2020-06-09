//
//  TableViewCell.swift
//  MusicPlayer
//
//  Created by Naveen kumar Oruganti on 29/05/20.
//  Copyright © 2020 Sandeep Athiyarath. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var music: UILabel!
    @IBOutlet weak var testphase: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func cellInit(title:String, singer: String, cover: UIImage){
        self.music.text = title
        self.testphase.text = singer
        //self.songImage.image = UIImage(named: "Cover1")
        self.songImage.image = cover
    }
    
}
