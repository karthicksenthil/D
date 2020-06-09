//
//  FavouriteViewController.swift
//  MusicPlayer
//
//  Created by Sandeep Athiyarath on 30/05/20.
//  Copyright © 2020 Sandeep Athiyarath. All rights reserved.
//

import UIKit

class FavouriteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // table view
    @IBOutlet weak var favMusicTable: UITableView!
    
    // function to set the number of rows in the table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        music.count
    }
    
    /* display the rows with data. All songs are given a default image in the table view.
        on moving to the player, image of the song is picked from mp3 metadata if present
        else, a default image is provided*/
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") as! TableViewCell
        let song = music[indexPath.row]

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
    
    // select a cell by clicking on it and pass details to player page
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let currentSong = indexPath.row

        guard let player = storyboard?.instantiateViewController(identifier: "player") as? MusicPlayerViewController else {
            return
        }
        player.songs = music
        player.currentSong = currentSong
        present(player, animated: true)
    }
    
    // swipe left to display remove from favorites button
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let removeFromFav = UIContextualAction(style: .normal, title: "Remove from favorites"){(action, view, nil) in
            self.selectedSong = self.music[indexPath.row]
            self.removeFromFavourites(song: self.selectedSong)
        }
        return UISwipeActionsConfiguration(actions: [removeFromFav])
    }
    
    var db: OpaquePointer?
    var music = [MusicDetails]()
    var selectedSong = MusicDetails(title: "", singer: "", album: "", cover: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "TableViewCell", bundle: nil)
        favMusicTable.register(nib, forCellReuseIdentifier: "TableViewCell")
        
        // file url for favourites
        let favFileUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("favourites.sqlite")
        
        //open favourites database
        if sqlite3_open(favFileUrl.path, &db) != SQLITE_OK{
            print("Error opening database")
            return
        }

        //create favourite table if not already created
        let createFavTableQuery = "CREATE TABLE IF NOT EXISTS favourites (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, singer TEXT, album TEXT, cover TEXT);"
        if sqlite3_exec(db, createFavTableQuery, nil, nil, nil) != SQLITE_OK{
            print("Error Creating table")
            return
        }
        
        favMusicTable.delegate = self
        favMusicTable.dataSource = self
        // function call to get all songs in the favourites table
        query()
    }
    
    // function to search for songs containing the name entered by the user from the favourites table
    func query() {
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

                music.append(MusicDetails(title: title, singer: singer, album: album, cover: cover))
            }
      } else {
          let errorMessage = String(cString: sqlite3_errmsg(db))
          print("\nQuery is not prepared \(errorMessage)")
      }
      sqlite3_finalize(queryStatement)
    }
    
    // function to remove the song from the favourites table and updates the table view
    func removeFromFavourites(song: MusicDetails){
        let deleteStatementQuery = "DELETE FROM favourites WHERE title = '" + song.title + "';"
        var deleteStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteStatementQuery, -1, &deleteStatement, nil) ==
            SQLITE_OK {
          if sqlite3_step(deleteStatement) == SQLITE_DONE {
            let alert = UIAlertController(title: "Alert", message: "Removed the song from playlist", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
          } else {
            print("\nCould not delete row.")
          }
        } else {
          print("\nDELETE statement could not be prepared")
        }
        
        sqlite3_finalize(deleteStatement)
        music.removeAll()
        
        // function call to update the favourites table view
        query()
        
        // reload the table with new updated details
        favMusicTable.reloadData()
    }
}
