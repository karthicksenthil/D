//
//  ViewController.swift
//  MusicPlayer
//
//  Created by Sandeep Athiyarath on 27/05/20.
//  Copyright © 2020 Sandeep Athiyarath. All rights reserved.
//

import UIKit
import SQLite3
import AVKit
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var favList = [MusicDetails]()
    var temp = [MusicDetails]()
    var selectedSong = MusicDetails(title: "", singer: "", album: "", cover: "")
    
    // set the number of rows for the table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return temp.count
    }
        
    // display the table with songs which matches with search option with a default image in table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") as! TableViewCell
        let song = temp[indexPath.row]

        cell.cellInit(title: song.title, singer: song.singer, cover: UIImage(named: "Cover1")!)
        return cell
    }
    
    // set fixed height for each cell
    var selectedIndex = -1
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == selectedIndex {
            return 90
        }else {
            return 90
        }
    }
    
    // swipe left to display add to favourite button
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let addToFav = UIContextualAction(style: .normal, title: "Add to favorites"){(action, view, nil) in
            self.selectedSong = self.temp[indexPath.row]
            self.addToFavourites(song: self.selectedSong)
        }
        return UISwipeActionsConfiguration(actions: [addToFav])
    }
    
    // select a cell by clicking on it and pass details to player view controller
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let currentSong = indexPath.row

        guard let player = storyboard?.instantiateViewController(identifier: "player") as? MusicPlayerViewController else {
            return
        }
        player.songs = temp
        player.currentSong = currentSong
        present(player, animated: true)
    }
    
    var db: OpaquePointer?
    var music = [MusicDetails]()
    
    @IBOutlet weak var musicTable: UITableView!
    
   /*
    This commented portion was initially used to enter data into the sql table. The text fields were removed and the
    related code was commented out. Kept for reference purpose
     
    @IBOutlet weak var singer: UITextField!
    @IBOutlet weak var album: UITextField!
    @IBOutlet weak var songname: UITextField!
    
    @IBOutlet weak var songcover: UITextField!*/
    // save the details to insert a new song to database
    /*@IBAction func saveButton(_ sender: Any) {
        let song = songname.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let albumName = album.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let singername = singer.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let covername = songcover.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        if(song?.isEmpty)!{
            print("Song name is empty")
            return
        }
        if(albumName?.isEmpty)!{
            print("album name is empty")
            return
        }
        if(singername?.isEmpty)!{
            print("singer name is empty")
            return
        }
        var stmt: OpaquePointer?
        let insertQuery = "INSERT INTO allsongs (title, singer, album, cover) VALUES (?, ?, ?, ?)"
         if sqlite3_prepare(db, insertQuery, -1, &stmt, nil) != SQLITE_OK{
            print("Error binding query")
        }
        
        if sqlite3_bind_text(stmt,1,song,-1,SQLITE_TRANSIENT) != SQLITE_OK{
            print("Error binding song name")
        }
        if sqlite3_bind_text(stmt,2,singername,-1,SQLITE_TRANSIENT) != SQLITE_OK{
            print("Error binding singer name")
        }
        if sqlite3_bind_text(stmt,3,albumName,-1,SQLITE_TRANSIENT) != SQLITE_OK{
            print("Error binding album name")
        }
        if sqlite3_bind_text(stmt,4,covername,-1,SQLITE_TRANSIENT) != SQLITE_OK{
            print("Error binding album name")
        }
        if sqlite3_step(stmt) == SQLITE_DONE {
            print("Song saved successfully")
        }
    }*/
    
    @IBOutlet weak var songSearched: UITextField!
    
    // search button to search for all songs that resembles the song name searched
    @IBAction func searchSongsButton(_ sender: Any) {
        let searched = songSearched.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if(searched?.isEmpty)!{
            let alert = UIAlertController(title: "Alert", message: "Song name is empty", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        //music.removeAll()
        //query(songName: searched!)
        filter(songname: searched!)
        //alert the user that the song name was not found
        
        musicTable.reloadData()
    }
    func filter(songname: String){
        temp = music.filter{
            $0.title.contains(songname)
        }
        if(temp.count == 0){
            let alert = UIAlertController(title: "Alert", message: "Could not find any match for the song you searched for", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "TableViewCell", bundle: nil)
        musicTable.register(nib, forCellReuseIdentifier: "TableViewCell")
        
        // file Url for music database
        guard let path = Bundle.main.path(forResource: "allsongs", ofType: "sqlite")
        else{
            print("file not found")
            return
        }

        //open music database
        if sqlite3_open(path, &db) != SQLITE_OK{
            print("Error opening database")
            return
        }
        query()
        // file url for favourites
        let favFileUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("favourites.sqlite")
        
        //open favourites database
        if sqlite3_open(favFileUrl.path, &db) != SQLITE_OK{
            print("Error opening database")
            return
        }
        
        // create the music table if not already present
        let createTableQuery = "CREATE TABLE IF NOT EXISTS allsongs (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, singer TEXT, album TEXT, cover TEXT);"
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK{
            print("Error Creating table")
            return
        }
        
        //create favourite table if not already created
        let createFavTableQuery = "CREATE TABLE IF NOT EXISTS favourites (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, singer TEXT, album TEXT, cover TEXT);"
        if sqlite3_exec(db, createFavTableQuery, nil, nil, nil) != SQLITE_OK{
            print("Error Creating table")
            return
        }
        
        musicTable.delegate = self
        musicTable.dataSource = self
    }
    
    // function to search for songs containing the name entered by the user
    func query() {
      var queryStatement: OpaquePointer?
        let queryStatementString = "SELECT * FROM allsongs;"
        music.removeAll()
        if sqlite3_prepare_v2(db,queryStatementString,-1,&queryStatement,nil) == SQLITE_OK {
            while (sqlite3_step(queryStatement) == SQLITE_ROW) {
              
              guard let queryResultCol1 = sqlite3_column_text(queryStatement, 1) else {
                print("Query result is nil.")
                return
              }
                guard let queryResultCol2 = sqlite3_column_text(queryStatement, 2) else {
                  print("Query result is nil.")
                  return
                }
                guard let queryResultCol3 = sqlite3_column_text(queryStatement, 3) else {
                  print("Query result is nil.")
                  return
                }
                guard let queryResultCol4 = sqlite3_column_text(queryStatement, 4) else {
                  print("Query result is nil.")
                  return
                }
      
                let title = String(cString: queryResultCol1)
                let singer = String(cString: queryResultCol2)
                let album = String(cString: queryResultCol3)
                let cover = String(cString: queryResultCol4)
                print(title)
                music.append(MusicDetails(title: title, singer: singer, album: album, cover: cover))
            }
      } else {
          let errorMessage = String(cString: sqlite3_errmsg(db))
          print("\nQuery is not prepared \(errorMessage)")
      }
      sqlite3_finalize(queryStatement)
    }
    
    // function to add songs to the favourites table
    func addToFavourites(song: MusicDetails){
        var alreadyFavourite = false
        favList.removeAll()
        allFavouriteSongs()
        
        // alert user if the song was already added to the favourites list
        for songs in favList{
            if(songs.title == song.title){
                let alert = UIAlertController(title: "Alert", message: "Song has already been added to favourites", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                alreadyFavourite = true;
            }
        }
        if(!alreadyFavourite){
            insertToFavTable(newFav: song)
        }
    }
    
    // extract all the songs in favourites table
    func allFavouriteSongs(){
        var queryStatement: OpaquePointer?
          let queryStatementString = "SELECT * FROM favourites;"

          if sqlite3_prepare_v2(db,queryStatementString,-1,&queryStatement,nil) == SQLITE_OK {
              while (sqlite3_step(queryStatement) == SQLITE_ROW) {
                //let id = sqlite3_column_int(queryStatement, 0)
                guard let queryResultCol1 = sqlite3_column_text(queryStatement, 1) else {
                  print("Query result is nil.")
                  return
                }
                  guard let queryResultCol2 = sqlite3_column_text(queryStatement, 2) else {
                    print("Query result is nil.")
                    return
                  }
                  guard let queryResultCol3 = sqlite3_column_text(queryStatement, 3) else {
                    print("Query result is nil.")
                    return
                  }
                guard let queryResultCol4 = sqlite3_column_text(queryStatement, 4) else {
                  print("Query result is nil.")
                  return
                }

                  let title = String(cString: queryResultCol1)
                  let singer = String(cString: queryResultCol2)
                  let album = String(cString: queryResultCol3)
                  let cover = String(cString: queryResultCol4)
                  favList.append(MusicDetails(title: title, singer: singer, album: album, cover: cover))
              }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("\nQuery is not prepared \(errorMessage)")
        }
        sqlite3_finalize(queryStatement)
    }
    
    // insert new rows to favourites table
    func insertToFavTable(newFav: MusicDetails){
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        var stmt: OpaquePointer?
        let insertQuery = "INSERT INTO favourites (title, singer, album, cover) VALUES (?, ?, ?, ?)"
         if sqlite3_prepare(db, insertQuery, -1, &stmt, nil) != SQLITE_OK{
            print("Error binding query")
        }
        
        if sqlite3_bind_text(stmt,1,newFav.title,-1,SQLITE_TRANSIENT) != SQLITE_OK{
            print("Error binding song name")
        }
        if sqlite3_bind_text(stmt,2,newFav.singer,-1,SQLITE_TRANSIENT) != SQLITE_OK{
            print("Error binding singer name")
        }
        if sqlite3_bind_text(stmt,3,newFav.album,-1,SQLITE_TRANSIENT) != SQLITE_OK{
            print("Error binding album name")
        }
        if sqlite3_bind_text(stmt,4,newFav.cover,-1,SQLITE_TRANSIENT) != SQLITE_OK{
            print("Error binding album name")
        }
        if sqlite3_step(stmt) == SQLITE_DONE {
            let alert = UIAlertController(title: "Alert", message: "Song added to favourites list", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

