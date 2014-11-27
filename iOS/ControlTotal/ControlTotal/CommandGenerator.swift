//
//  CommandGenerator.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 25/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//
enum BasicCommand{
    case Open, Close, Play, Stop, Pause, Forward, Backward, Volume, Info, Search
}
enum AppsSupported:String{
    case System = "System"
    case iTunes = "iTunes"
    case Spotify = "Spotify"
}

struct CommandGenerator {
    static var AS_PREFIX = "osascript -e "
    
    var playerProperties:Dictionary<String, String> = ["track": "", "artist": "", "album":"", "totalMinutes":"", "totalSeconds":"", "currentMinutes":"", "currentSeconds" : "", "state":"", "volume": ""]
    
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
            case .Stop:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to stop'"
            case .Pause:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to pause'"
            case .Forward:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to next track'"
            case .Backward:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to previous track'"
            case .Open:
                return "open -a \(app.rawValue)"
            case .Volume:
                return AS_PREFIX+"'tell application \"\(app.rawValue)\" to set sound volume to \(extra)'"
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
                    script+=" -e 'set tM to round (duration of current track / 60) rounding down'"
                    script+=" -e 'set tS to duration of current track mod 60'"
                    script+=" -e 'set nM to round (player position / 60) rounding down'"
                    script+=" -e 'set nS to round (player position mod 60) rounding down'"
                    script+=" -e 'return \"track:|:\" & myTrack & \"||\" & \"artist:|:\" & myArtist & \"||\" &  \"album:|:\" & myAlbum & \"||\" & \"totalMinutes:|:\" & tM & \"||\" & \"totalSeconds:|:\" & tS & \"||\" & \"currentMinutes:|:\" & nM & \"||\" & \"currentSeconds:|:\" & nS & \"||\" & \"state:|:\" & player state & \"||\" & \"volume:|:\" & sound volume'"
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