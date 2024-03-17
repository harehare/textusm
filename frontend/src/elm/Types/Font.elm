module Types.Font exposing (Font, FontLocation, googleFont, localFont, name, url)


type alias FontName =
    String


type FontLocation
    = Local
    | Google


type Font
    = Font FontName FontLocation


url : Font -> String
url font =
    case font of
        Font n Google ->
            "https://fonts.googleapis.com/css2?family=" ++ n ++ "&display=swap"

        Font n Local ->
            "fonts/" ++ n


googleFont : String -> Font
googleFont n =
    Font n Google


localFont : String -> Font
localFont n =
    Font n Local


name : Font -> String
name (Font n _) =
    n
