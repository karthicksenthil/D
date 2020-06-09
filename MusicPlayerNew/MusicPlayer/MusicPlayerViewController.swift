//
//  MusicPlayerViewController.swift
//  MusicPlayer
//
//  Created by Sandeep Athiyarath on 30/05/20.
//  Copyright © 2020 Sandeep Athiyarath. All rights reserved.
//
import AVFoundation
import UIKit

class MusicPlayerViewController: UIViewController, AVAudioPlayerDelegate {
    var currentSong: Int = 0
    var songs: [MusicDetails] = []

    var musicPlayer: AVAudioPlayer?

    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    
    @IBOutlet weak var songCover: UIImageView!
    
    
    @IBOutlet weak var timeSlider: UISlider!
    
    @IBAction func changeTimeSlider(_ sender: Any) {
        musicPlayer?.stop()
        musicPlayer?.currentTime = TimeInterval(timeSlider.value)
        musicPlayer?.prepareToPlay()
        musicPlayer?.play()
    }
    @objc func updateslider(){
        timeSlider.value = Float(musicPlayer!.currentTime)
        //print(timeSlider.value)
    }
    
    // button to control the play/ pause action
    @IBAction func playPauseAction(_ sender: Any) {
        
        //toggle the play/pause button background
        if musicPlayer?.isPlaying == true {
            musicPlayer?.pause()
            playPauseButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        else{
            musicPlayer?.play()
            playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    // button to move to the next button
    @IBAction func nextSong(_ sender: Any) {
        if currentSong < (songs.count - 1) {
            currentSong = currentSong + 1
        }
        else{
            currentSong = 0
        }
        configure()
    }
    
    // button to play the previous song
    @IBAction func previousSong(_ sender: Any) {
        if currentSong > 0 {
            currentSong = currentSong - 1
        }
        else{
            currentSong = songs.count - 1
        }
        musicPlayer?.stop()
        configure()
    }
    
    // UI button variables for play, next and previous options to set background images
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    
    
    @IBOutlet weak var volumeIcon: UIButton!
    // slider declaration for controlling volume
    @IBAction func volumeControl(_ sender: UISlider) {
        let volumeLevel = sender.value
        musicPlayer?.volume = volumeLevel
        if(volumeLevel >= 0.75){
            volumeIcon.setBackgroundImage(UIImage(systemName: "speaker.3.fill"), for: .normal)
        }else if(volumeLevel >= 0.5){
            volumeIcon.setBackgroundImage(UIImage(systemName: "speaker.2.fill"), for: .normal)
        }else if(volumeLevel > 0){
            volumeIcon.setBackgroundImage(UIImage(systemName: "speaker.1.fill"), for: .normal)
        }else{
            volumeIcon.setBackgroundImage(UIImage(systemName: "speaker.slash.fill"), for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        timeSlider.maximumValue = Float(musicPlayer!.duration)
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateslider), userInfo: nil, repeats: true)
    }

    // configure the player view controller and start playing the current song
    func configure() {
        let song = songs[currentSong]
        
        /* TO BE USED IF SONGS ARE KEPT IN THE DOCUMENTS DIRECTORY*/
        /*let paths: [AnyObject] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as [AnyObject]
        
        let newPathComponent = "/" + song.title + ".mp3"
        let audiofilePath = paths[0].appending(newPathComponent)*/
        //print(audiofilePath)
        
        /*  CHANGE THE PATHWAY TO THE FOLDER WHERE THE SONGS ARE KEPT */
        let urlString: String? = "/Users/102005528/Desktop/songs/" + song.title + ".mp3"
        
        do {
            try AVAudioSession.sharedInstance().setMode(.default)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            guard let urlString = urlString else {
                print("urlstring is nil")
                return
            }
            
            /*
             assign default cover and pick details from music table
             */
            songCover.image = UIImage(named: "default")
            songNameLabel.text = song.title
            artistNameLabel.text = song.singer
            albumNameLabel.text = song.album
            
            /*
             Pick song details and cover from the mp3 meta data if available
             */
            let fileUrl = NSURL(fileURLWithPath: urlString)
            //let fileUrl = NSURL(fileURLWithPath: audiofilePath)
            
            let asset = AVAsset(url: fileUrl as URL) as AVAsset
            for metaDataItems in asset.commonMetadata {
                
                //getting the title of the song
                if metaDataItems.commonKey!.rawValue == "title" {
                    let titleData = metaDataItems.value as! NSString
                    songNameLabel.text = titleData as String
                }
                
                //getting the "Artist of the mp3 file"
                if metaDataItems.commonKey!.rawValue == "artist" {
                    let artistData = metaDataItems.value as! NSString
                    artistNameLabel.text = artistData as String
                }
                
                //getting the thumbnail image associated with file
                if metaDataItems.commonKey!.rawValue == "artwork" {
                    let imageData = metaDataItems.value as! NSData
                    let image2: UIImage = UIImage(data: imageData as Data)!
                    songCover.image = image2
                }
            }
            print(urlString)
            //play music from path
            let songPath = URL(string: urlString)
            //let songPath = URL(string: audiofilePath)
            
            musicPlayer = try AVAudioPlayer(contentsOf: songPath!)
            guard let musicPlayer = musicPlayer else {
                print("player is nil")
                return
            }
            volumeIcon.setBackgroundImage(UIImage(systemName: "speaker.2.fill"), for: .normal)
            musicPlayer.volume = 0.5
            
            musicPlayer.play()
            musicPlayer.delegate = self
        }
        catch {
            print("error occurred" + error.localizedDescription)
        }
        timeSlider.maximumValue = Float(musicPlayer!.duration)
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateslider), userInfo: nil, repeats: true)
        // set background images for the buttons
        playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
        previousButton.setBackgroundImage(UIImage(systemName: "backward.fill"), for: .normal)
        nextButton.setBackgroundImage(UIImage(systemName: "forward.fill"), for: .normal)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let musicPlayer = musicPlayer {
            musicPlayer.stop()
        }
    }
 
    // function to automatically play the next song on completing the current song
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            currentSong += 1
        }
        
        if ((currentSong) == songs.count) {
            currentSong = 0
        }
        configure()
    }
}
