module Utils exposing (calcDistance, calcFontSize, delay, fileLoad, getCanvasSize, getIdToken, getMarkdownHeight, getTitle, httpErrorToString, isImageUrl, isPhone, millisToString, monthToInt, showErrorMessage, showInfoMessage, showWarningMessage)

import Constants
import File exposing (File)
import Http exposing (Error(..))
import Models.Diagram as DiagramModel
import Models.DiagramType as DiagramType
import Models.IdToken exposing (IdToken)
import Models.Item as Item
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
            min (String.length text) 15
    in
    String.fromInt (Basics.min (width // size) 15)


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


showWarningMessage : String -> Cmd Msg
showWarningMessage msg =
    Task.perform identity (Task.succeed (OnNotification (Warning msg)))


showInfoMessage : String -> Cmd Msg
showInfoMessage msg =
    Task.perform identity (Task.succeed (OnNotification (Info msg)))


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


isImageUrl : String -> Bool
isImageUrl url =
    (String.startsWith "/" url || String.startsWith "https://" url || String.startsWith "http://" url)
        && (String.endsWith ".svg" url || String.endsWith ".png" url || String.endsWith ".jpg" url)


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


getMarkdownHeight : List String -> Int
getMarkdownHeight lines =
    let
        getHeight : String -> Int
        getHeight line =
            case String.toList line of
                '#' :: '#' :: '#' :: '#' :: '#' :: _ ->
                    24

                '#' :: '#' :: '#' :: '#' :: _ ->
                    32

                '#' :: '#' :: '#' :: _ ->
                    40

                '#' :: '#' :: _ ->
                    48

                '#' :: _ ->
                    56

                _ ->
                    24
    in
    lines |> List.map (\l -> getHeight l) |> List.sum


getCanvasSize : DiagramModel.Model -> ( Int, Int )
getCanvasSize model =
    let
        ( width, height ) =
            case model.diagramType of
                DiagramType.FourLs ->
                    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.largeItemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 2 + 20 )

                DiagramType.EmpathyMap ->
                    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.largeItemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 2 + 20 )

                DiagramType.OpportunityCanvas ->
                    ( Constants.itemWidth * 5 + 20, Basics.max Constants.itemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 3 + 20 )

                DiagramType.BusinessModelCanvas ->
                    ( Constants.itemWidth * 5 + 20, Basics.max Constants.itemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 3 + 20 )

                DiagramType.Kpt ->
                    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.itemHeight (30 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 2 + 20 )

                DiagramType.StartStopContinue ->
                    ( Constants.itemWidth * 3 + 20, Basics.max Constants.largeItemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) + 20 )

                DiagramType.UserPersona ->
                    ( Constants.itemWidth * 5 + 25, Basics.max Constants.itemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0)) * 2 + 20 )

                DiagramType.Markdown ->
                    ( 15 * (Maybe.withDefault 1 <| List.maximum <| List.map (\s -> String.length s) <| String.lines <| Maybe.withDefault "" <| model.text), getMarkdownHeight <| String.lines <| Maybe.withDefault "" <| model.text )

                DiagramType.MindMap ->
                    ( (model.settings.size.width + 100) * ((model.hierarchy + 1) * 2 + 1) + 100
                    , case List.head model.items of
                        Just head ->
                            Item.getLeafCount head * (model.settings.size.height + 15)

                        Nothing ->
                            0
                    )

                DiagramType.CustomerJourneyMap ->
                    ( model.settings.size.width * (List.length model.items + 1)
                    , model.settings.size.height * ((model.items |> List.head |> Maybe.withDefault Item.emptyItem |> .children |> Item.unwrapChildren |> List.length) + 1) + Constants.itemMargin
                    )

                _ ->
                    ( Constants.leftMargin + Constants.itemMargin + (model.settings.size.width + Constants.itemMargin * 2) * (List.maximum model.countByTasks |> Maybe.withDefault 1), (model.settings.size.height + Constants.itemMargin) * (List.sum model.countByHierarchy + 2) )
    in
    ( width, height )


calcDistance : ( Float, Float ) -> ( Float, Float ) -> Float
calcDistance ( x1, y1 ) ( x2, y2 ) =
    sqrt (((x2 - x1) ^ 2) + ((y2 - y1) ^ 2))
