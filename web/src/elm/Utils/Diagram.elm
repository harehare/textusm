module Utils.Diagram exposing (getCanvasHeight, getSpacePrefix)

import Constants
import List.Extra as ListEx
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Items)


getCanvasHeight : DiagramSettings.Settings -> Items -> Int
getCanvasHeight settings items =
    let
        taskCount : Maybe Int
        taskCount =
            Item.map (\i -> Item.getChildren i |> Item.unwrapChildren |> Item.length) items
                |> List.maximum
    in
    (settings.size.height + Constants.itemMargin) * (taskCount |> Maybe.withDefault 1) + 50


getSpacePrefix : String -> String
getSpacePrefix text =
    (text
        |> String.toList
        |> ListEx.takeWhile (\c -> c == ' ')
        |> List.length
        |> String.repeat
    )
        " "
