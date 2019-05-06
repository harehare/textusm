module Utils exposing (calcFontSize, delay, fileLoad, getTitle, isPhone)

import File exposing (File)
import Models.Model exposing (Msg(..))
import Process
import Task


calcFontSize : Int -> String -> String
calcFontSize width text =
    let
        size =
            min (String.length text) 11
    in
    String.fromInt (Basics.min (width // size) 11)


isPhone : Int -> Bool
isPhone width =
    width <= 480


fileLoad : File -> (String -> Msg) -> Cmd Msg
fileLoad file msg =
    Task.perform msg (File.toString file)


getTitle : Maybe String -> String
getTitle title =
    case title of
        Just t ->
            t

        Nothing ->
            "untitled"


delay : Float -> Msg -> Cmd Msg
delay time msg =
    Process.sleep time
        |> Task.perform (\_ -> msg)
