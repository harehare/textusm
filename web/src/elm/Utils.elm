module Utils exposing (calcFontSize, delay, fileLoad, getCanvasSize, getIdToken, getTitle, httpErrorToString, isPhone, millisToString, monthToInt, showErrorMessage, showInfoMessage, showWarningMessage)

import Constants
import File exposing (File)
import Http exposing (Error(..))
import Models.Diagram as DiagramModel
import Models.DiagramType as DiagramType
import Models.IdToken as IdToken exposing (IdToken)
import Models.Model exposing (Msg(..), Notification(..))
import Models.User as User exposing (User)
import Process
import Task
import Time exposing (Month(..), Zone, millisToPosix, toDay, toMonth, toYear)


getIdToken : Maybe User -> Maybe IdToken
getIdToken user =
    Maybe.map (\u -> User.getIdToken u) user


calcFontSize : Int -> String -> String
calcFontSize width text =
    let
        size =
            min (String.length text) 13
    in
    String.fromInt (Basics.min (width // size) 13)


isPhone : Int -> Bool
isPhone width =
    width <= 480


fileLoad : File -> (String -> Msg) -> Cmd Msg
fileLoad file msg =
    Task.perform msg (File.toString file)


getTitle : Maybe String -> String
getTitle title =
    title |> Maybe.withDefault "untitled"


delay : Float -> Msg -> Cmd Msg
delay time msg =
    Process.sleep time
        |> Task.perform (\_ -> msg)


showWarningMessage : String -> Maybe String -> Cmd Msg
showWarningMessage msg openURL =
    Task.perform identity (Task.succeed (OnNotification (Warning msg openURL)))


showInfoMessage : String -> Maybe String -> Cmd Msg
showInfoMessage msg openURL =
    Task.perform identity (Task.succeed (OnNotification (Info msg openURL)))


showErrorMessage : String -> Cmd Msg
showErrorMessage msg =
    Task.perform identity (Task.succeed (OnNotification (Error msg)))


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


millisToString : Zone -> Int -> String
millisToString timezone millis =
    let
        posix =
            millisToPosix millis
    in
    String.fromInt (toYear timezone posix)
        ++ "-"
        ++ String.fromInt (monthToInt (toMonth timezone posix))
        ++ "-"
        ++ String.fromInt (toDay timezone posix)


monthToInt : Month -> Int
monthToInt month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


getCanvasSize : DiagramModel.Model -> DiagramType.DiagramType -> ( Int, Int )
getCanvasSize model diagramType =
    let
        width =
            case diagramType of
                DiagramType.FourLs ->
                    Constants.itemWidth * 2 + 20

                DiagramType.OpportunityCanvas ->
                    Constants.itemWidth * 5 + 20

                DiagramType.BusinessModelCanvas ->
                    Constants.itemWidth * 5 + 20

                DiagramType.Kpt ->
                    Constants.largeItemWidth * 2 + 20

                DiagramType.StartStopContinue ->
                    Constants.itemWidth * 3 + 20

                DiagramType.UserPersona ->
                    Constants.itemWidth * 5 + 25

                _ ->
                    (model.settings.size.width + Constants.itemMargin) * (List.maximum model.countByTasks |> Maybe.withDefault 1)

        height =
            case model.diagramType of
                DiagramType.FourLs ->
                    Basics.max Constants.largeItemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 2 + 20

                DiagramType.OpportunityCanvas ->
                    Basics.max Constants.itemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 3 + 20

                DiagramType.BusinessModelCanvas ->
                    Basics.max Constants.itemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 3 + 20

                DiagramType.Kpt ->
                    Basics.max Constants.itemHeight (30 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 2 + 20

                DiagramType.StartStopContinue ->
                    Basics.max Constants.largeItemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) + 20

                DiagramType.UserPersona ->
                    Basics.max Constants.itemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 2 + 20

                _ ->
                    (model.settings.size.height + Constants.itemMargin) * (List.sum model.countByHierarchy + 2)
    in
    ( width, height )
