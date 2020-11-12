module Utils.Utils exposing (calcDistance, delay, httpErrorToString, isPhone)

import Constants
import Data.Item as Item exposing (Items)
import Data.Text as Text
import Http exposing (Error(..))
import List.Extra exposing (getAt, last, scanl1, takeWhile, unique)
import Models.Diagram as DiagramModel
import Models.Views.ER as ER exposing (Table(..))
import Models.Views.Kanban as Kanban
import Models.Views.SequenceDiagram as SequenceDiagram
import Models.Views.UserStoryMap as UserStoryMap
import Process
import Task
import TextUSM.Enum.Diagram as Diagram
import Time exposing (Month(..), Posix, Zone, toDay, toHour, toMinute, toMonth, toSecond, toYear, utc)
import Time.Extra exposing (Interval(..), Parts, diff, partsToPosix)
import Utils.Date as DateUtils


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
