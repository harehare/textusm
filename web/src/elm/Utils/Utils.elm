module Utils.Utils exposing (calcDistance, delay, httpErrorToString, isPhone)

import Http exposing (Error(..))
import Process
import Task


isPhone : Int -> Bool
isPhone width =
    width <= 480


delay : Float -> msg -> Cmd msg
delay time msg =
    Process.sleep time
        |> Task.perform (\_ -> msg)


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        BadUrl url ->
            "Invalid url " ++ url

        Timeout ->
            "Timeout error. Please try again later."

        NetworkError ->
            "Network error. Please try again later."

        _ ->
            "Internal server error. Please try again later."


calcDistance : ( Float, Float ) -> ( Float, Float ) -> Float
calcDistance ( x1, y1 ) ( x2, y2 ) =
    sqrt (((x2 - x1) ^ 2) + ((y2 - y1) ^ 2))
