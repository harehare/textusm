module Utils.Common exposing
    ( calcDistance
    , delay
    , getCanvasHeight
    , httpErrorToString
    , isPhone
    )

import Constants
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Settings as DiagramSettings
import Http exposing (Error(..))
import Process
import Task
import Types.Item as Item exposing (Items)


calcDistance : ( Float, Float ) -> ( Float, Float ) -> Float
calcDistance ( x1, y1 ) ( x2, y2 ) =
    sqrt (((x2 - x1) ^ 2) + ((y2 - y1) ^ 2))


delay : Float -> msg -> Cmd msg
delay time msg =
    Process.sleep time
        |> Task.perform (\_ -> msg)


httpErrorToString : Error -> String
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


isPhone : Int -> Bool
isPhone width =
    width <= 480


getCanvasHeight : DiagramSettings.Settings -> Items -> Int
getCanvasHeight settings items =
    let
        taskCount : Maybe Int
        taskCount =
            Item.map (\i -> Item.getChildren i |> Item.unwrapChildren |> Item.length) items
                |> List.maximum
    in
    (CardSize.toInt settings.size.height + Constants.itemMargin) * (taskCount |> Maybe.withDefault 1) + 50
