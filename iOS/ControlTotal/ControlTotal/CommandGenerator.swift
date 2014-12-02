//
//  CommandGenerator.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 25/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

enum BasicCommand{
    case Open, Close, Play, Stop, Pause, Next, Back, Forward, Rewind, Jump, Volume, Info, Search, Rating, Visuals, Artwork
}
enum AppsSupported:String{
    case System = "System"
    case iTunes = "iTunes"
    case Spotify = "Spotify"
    case VLC = "VLC"
}

struct CommandGenerator {
    static var AS_PREFIX = "osascript -e "
    
    var playerProperties:Dictionary<String, String> = ["track": "", "artist": "", "album":"", "totalMinutes":"", "totalSeconds":"", "currentMinutes":"", "currentSeconds" : "", "state":"", "volume": "", "rating": "", "visuals": ""]
    
    static func app(app:AppsSupported, command: BasicCommand, extra:String = "") -> String{
        switch command {
            case .Play:
                var script:String = "'tell application \"System Events\"'"
                script+=" -e 'if exists process \"\(app.rawValue)\" then'"
                script+=" -e 'tell application \"\(app.rawValue)\"'"
                script+=" -e 'set theCurrentState to player state'"
                script+=" -e 'if theCurrentState is paused then'"
                script+=" -e 'tell application \"\(app.rawValue)\" to play'"
                script+=" -e 'else if theCurrentState is stopped then'"
                script+=" -e 'tell application \"\(app.rawValue)\" to play'"
                script+=" -e 'else if theCurrentState is playing then'"
                script+=" -e 'tell application \"\(app.rawValue)\" to pause'"
                script+=" -e 'else'"
                script+=" -e 'end if'"
                script+=" -e 'end tell'"
                script+=" -e 'else'"
                script+=" -e 'run application \"\(app.rawValue)\"'"
                script+=" -e 'delay 2.5'"
                script+=" -e 'tell application \"\(app.rawValue)\" to play'"
                script+=" -e 'end if'"
                script+=" -e 'end tell'"
                return AS_PREFIX+script
            
            case .Artwork:
                var script:String = "'tell application \"\(app.rawValue)\"'"
                script+=" -e 'my e_(\(extra), (path to temporary items) as text, \"myartworkpic\")'"
                script+=" -e 'end tell'"
                
                script+=" -e 'to e_(theTrack, exportFolder, artworkName)'"
                script+=" -e 'tell application \"\(app.rawValue)\"'"
                script+=" -e 'try'"
                script+=" -e 'tell theTrack to set {artworkData, imageFormat} to {(raw data of artwork 1), (format of artwork 1) as text}'"
                script+=" -e 'on error'"
                script+=" -e 'return false'"
                script+=" -e 'end try'"
                script+=" -e 'end tell'"
                
                script+=" -e 'set ext to \".png\"'"
                script+=" -e 'set fileType to \"PNG\"'"
                script+=" -e 'if imageFormat contains \"JPEG\" then'"
                script+=" -e 'set ext to \".jpg\"'"
                script+=" -e 'set fileType to \"JPEG\"'"
                script+=" -e 'end if'"
                
                script+=" -e 'set pathToNewFile to (exportFolder & artworkName & ext) as text'"
                
                script+=" -e 'try'"
                script+=" -e 'do shell script \"rm \" & quoted form of POSIX path of pathToNewFile'"
                script+=" -e 'end try'"
                
                script+=" -e 'try'"
                script+=" -e 'set fileRef to (open for access pathToNewFile with write permission)'"
                script+=" -e 'set eof fileRef to 0'"
                script+=" -e 'write artworkData to fileRef starting at 0'"
                script+=" -e 'close access fileRef'"
                script+=" -e 'on error m'"
                script+=" -e 'try'"
                script+=" -e 'close access fileRef'"
                script+=" -e 'end try'"
                script+=" -e 'return false'"
                script+=" -e 'end try'"
                
                script+=" -e 'try'"
                script+=" -e 'tell application \"System Events\" to set file type of (pathToNewFile as alias) to fileType'"
                script+=" -e 'on error m'"
                script+=" -e 'log (\"ERROR: \" & m)'"
                script+=" -e 'end try'"
                
                script+=" -e 'return pathToNewFile'"
                script+=" -e 'end exportArtwork_'"
            return AS_PREFIX+script
            
            case .Stop:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to stop'"
            case .Pause:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to pause'"
            case .Next:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to next track'"
            case .Back:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to previous track'"
            case .Forward:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to set player position to (player position + \(extra))'"
            case .Rewind:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to set player position to (player position - \(extra))'"
            case .Jump:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to set player position to \(extra)'"
            case .Open:
                return "open -a \(app.rawValue)"
            case .Visuals:
                var script:String = "'tell application \"\(app.rawValue)\"'"
                script+=" -e 'activate'"
                
                script+=" -e 'if full screen is false then'"
                script+=" -e 'set full screen to true'"
                script+=" -e 'end if'"
                
                script+=" -e 'if visuals enabled is false then'"
                script+=" -e 'set visuals enabled to true'"
                script+=" -e 'else'"
                script+=" -e 'set visuals enabled to false'"
                script+=" -e 'end if'"
                
                script+=" -e 'end tell'"
                return AS_PREFIX+script
            case .Volume:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to set sound volume to \(extra)'"
            case .Rating:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to set rating of current track to \(extra)'"
            case .Search:
                    var script:String = "'tell application \"\(app.rawValue)\"'"
                script+=" -e 'set results to (every file track whose name contains \"\(extra)\" or artist contains \"\(extra)\")"
                script+=" -e 'set myList to {}'"
                script+=" -e 'repeat with t in results'"
                script+=" -e 'set myList to myList & {{track:get name of t, artist:get artist of t}}'"
                script+=" -e 'end repeat'"
                script+=" -e 'return myList'"
                script+=" -e 'end tell'"
                return AS_PREFIX+script
            case .Info:
                var script:String = "'tell application \"\(app.rawValue)\"'"
                    script+=" -e 'set myTrack to name of current track'"
                    script+=" -e 'set myArtist to artist of current track'"
                    script+=" -e 'set myAlbum to album of current track'"
                    script+=" -e 'set myRating to (get rating of current track)'"
                    script+=" -e 'set myVisuals to 1'"
                    script+=" -e 'if visuals enabled is false'"
                    script+=" -e 'set myVisuals to 0'"
                    script+=" -e 'end if'"
                    script+=" -e 'set tM to round (duration of current track / 60) rounding down'"
                    script+=" -e 'set tS to duration of current track mod 60'"
                    script+=" -e 'set nM to round (player position / 60) rounding down'"
                    script+=" -e 'set nS to round (player position mod 60) rounding down'"
                    script+=" -e 'return \"track:|:\" & myTrack & \"||\" & \"artist:|:\" & myArtist & \"||\" &  \"album:|:\" & myAlbum & \"||\" & \"totalMinutes:|:\" & tM & \"||\" & \"totalSeconds:|:\" & tS & \"||\" & \"currentMinutes:|:\" & nM & \"||\" & \"currentSeconds:|:\" & nS & \"||\" & \"state:|:\" & player state  & \"||\" & \"visuals:|:\" & myVisuals & \"||\" & \"volume:|:\" & sound volume & \"||\" & \"rating:|:\" & myRating'"
                    script+=" -e 'end tell'"
                return AS_PREFIX+script
            default:
                return AS_PREFIX
        }
    }
    
    mutating func handleResponse(command:BasicCommand, response:String) -> Dictionary <String,String>{
        switch command {
            case .Info:
            var tokens:[String] = response.componentsSeparatedByString("||")
            if(tokens.count == self.playerProperties.count){
                for token in tokens{
                    let key:[String] = token.componentsSeparatedByString(":|:")
                    self.playerProperties.updateValue(key[1], forKey: key[0])
                }
            }
            return self.playerProperties
        default:
            return ["response":response]
        }
    }
}