//
//  Icons.swift
//  Aqualert
//
//  Created by Ruben Velazquez Calva on 13/11/14.
//  Copyright (c) 2014 overseasolutions. All rights reserved.
//

/*
enum IconSet {
    case Folder, Literature, Micro, Movie, Museum, MusicTranscript, MusicVideo, Music, Photo, Physics, Piano, Presentation, Signal, ShoppingBag, StackPhotos, TrainTicket, Trash, TvShow, Tv, Wifi
}
*/

struct Icons {
    static func get(type:String) -> UIImage {
        var iconName = ""
        switch type{
        case "Library":
            iconName = "museum.png"
        case "Music":
            iconName = "music_icon.png"
        case "Movies":
            iconName = "movie.png"
        case "TV Shows":
            iconName = "tv_show.png"
        case "Podcasts":
            iconName = "micro.png"
        case "iTunes U":
            iconName = "student.png"
        case "Books":
            iconName = "literature.png"
        case "Purchased Music":
            iconName = "shopping_bag.png"
        case "Genius":
            iconName = "physics.png"
        default:
            iconName = "music_transcript.png"
        }
        
        return UIImage(named: iconName)!
    }
}