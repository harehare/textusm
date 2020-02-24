module Utils exposing (calcDistance, calcFontSize, delay, extractDateValues, fileLoad, getCanvasHeight, getCanvasSize, getIdToken, getMarkdownHeight, getSpacePrefix, getTitle, httpErrorToString, intToMonth, isImageUrl, isPhone, millisToString, monthToInt, showErrorMessage, showInfoMessage, showWarningMessage, stringToPosix)

import Constants
import File exposing (File)
import Http exposing (Error(..))
import List.Extra exposing (getAt, last, scanl1, takeWhile)
import Models.Diagram as DiagramModel
import Models.IdToken exposing (IdToken)
import Models.Item as Item
import Models.Model exposing (Msg(..), Notification(..))
import Models.User as User exposing (User)
import Process
import Task
import TextUSM.Enum.Diagram as Diagram
import Time exposing (Month(..), Posix, Zone, toDay, toHour, toMinute, toMonth, toSecond, toYear, utc)
import Time.Extra exposing (Interval(..), Parts, diff, partsToPosix)


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


zeroPadding : Int -> Int -> String
zeroPadding num value =
    String.fromInt value
        |> String.padLeft num '0'
        |> String.right num


millisToString : Zone -> Posix -> String
millisToString timezone posix =
    String.fromInt (toYear timezone posix)
        ++ "-"
        ++ (monthToInt (toMonth timezone posix) |> zeroPadding 2)
        ++ "-"
        ++ (toDay timezone posix |> zeroPadding 2)
        ++ " "
        ++ (toHour timezone posix |> zeroPadding 2)
        ++ ":"
        ++ (toMinute timezone posix |> zeroPadding 2)
        ++ ":"
        ++ (toSecond timezone posix |> zeroPadding 2)


intToMonth : Int -> Month
intToMonth month =
    case month of
        1 ->
            Jan

        2 ->
            Feb

        3 ->
            Mar

        4 ->
            Apr

        5 ->
            May

        6 ->
            Jun

        7 ->
            Jul

        8 ->
            Aug

        9 ->
            Sep

        10 ->
            Oct

        11 ->
            Nov

        12 ->
            Dec

        _ ->
            Jan


stringToPosix : String -> Maybe Posix
stringToPosix str =
    let
        tokens =
            String.split "-" str

        year =
            getAt 0 tokens
                |> Maybe.andThen
                    (\v ->
                        if String.length v == 4 then
                            String.toInt v

                        else
                            Nothing
                    )

        month =
            getAt 1 tokens
                |> Maybe.andThen
                    (\v ->
                        if String.length v == 2 then
                            String.toInt v
                                |> Maybe.andThen
                                    (\vv ->
                                        Just <| intToMonth vv
                                    )

                        else
                            Nothing
                    )

        day =
            getAt 2 tokens
                |> Maybe.andThen
                    (\v ->
                        if String.length v == 2 then
                            String.toInt v

                        else
                            Nothing
                    )
    in
    year
        |> Maybe.andThen
            (\yearValue ->
                month
                    |> Maybe.andThen
                        (\monthValue ->
                            day
                                |> Maybe.andThen
                                    (\dayValue ->
                                        Just <| partsToPosix utc (Parts yearValue monthValue dayValue 0 0 0 0)
                                    )
                        )
            )


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


extractDateValues : String -> Maybe ( Posix, Posix )
extractDateValues s =
    let
        rangeValues =
            String.split "," (String.trim s)

        fromDate =
            getAt 0 rangeValues
                |> Maybe.andThen
                    (\vv ->
                        stringToPosix (String.trim vv)
                    )

        toDate =
            getAt 1 rangeValues
                |> Maybe.andThen
                    (\vv ->
                        stringToPosix (String.trim vv)
                    )
    in
    fromDate
        |> Maybe.andThen
            (\from ->
                toDate
                    |> Maybe.andThen
                        (\to ->
                            Just ( from, to )
                        )
            )


getCanvasHeight : DiagramModel.Model -> Int
getCanvasHeight model =
    let
        taskCount =
            List.map (\i -> Item.unwrapChildren i.children |> List.length) model.items
                |> List.maximum
    in
    (model.settings.size.height + Constants.itemMargin) * (taskCount |> Maybe.withDefault 0) + 50


getCanvasSize : DiagramModel.Model -> ( Int, Int )
getCanvasSize model =
    let
        ( width, height ) =
            case model.diagramType of
                Diagram.Fourls ->
                    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.itemHeight (getCanvasHeight model) * 2 + 50 )

                Diagram.EmpathyMap ->
                    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.itemHeight (getCanvasHeight model) * 2 + 50 )

                Diagram.OpportunityCanvas ->
                    ( Constants.itemWidth * 5 + 20, Basics.max Constants.itemHeight (getCanvasHeight model) * 3 + 50 )

                Diagram.BusinessModelCanvas ->
                    ( Constants.itemWidth * 5 + 20, Basics.max Constants.itemHeight (getCanvasHeight model) * 3 + 50 )

                Diagram.Kpt ->
                    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.itemHeight (getCanvasHeight model) * 2 + 50 )

                Diagram.StartStopContinue ->
                    ( Constants.itemWidth * 3 + 20, Basics.max Constants.itemHeight (getCanvasHeight model) + 50 )

                Diagram.UserPersona ->
                    ( Constants.itemWidth * 5 + 25, Basics.max Constants.itemHeight (getCanvasHeight model) * 2 + 50 )

                Diagram.Markdown ->
                    ( 15 * (Maybe.withDefault 1 <| List.maximum <| List.map (\s -> String.length s) <| String.lines <| Maybe.withDefault "" <| model.text), getMarkdownHeight <| String.lines <| Maybe.withDefault "" <| model.text )

                Diagram.MindMap ->
                    ( (model.settings.size.width + 100) * ((model.hierarchy + 1) * 2 + 1) + 100
                    , case List.head model.items of
                        Just head ->
                            Item.getLeafCount head * (model.settings.size.height + 15)

                        Nothing ->
                            0
                    )

                Diagram.CustomerJourneyMap ->
                    ( model.settings.size.width * ((model.items |> List.head |> Maybe.withDefault Item.emptyItem |> .children |> Item.unwrapChildren |> List.length) + 1)
                    , model.settings.size.height * List.length model.items + Constants.itemMargin
                    )

                Diagram.SiteMap ->
                    let
                        items =
                            model.items
                                |> List.head
                                |> Maybe.withDefault Item.emptyItem
                                |> .children
                                |> Item.unwrapChildren

                        hierarchy =
                            items
                                |> List.map (\item -> Item.getHierarchyCount item)
                                |> List.sum

                        svgWidth =
                            (model.settings.size.width
                                + Constants.itemSpan
                            )
                                * List.length items
                                + Constants.itemSpan
                                * hierarchy

                        maxChildrenCount =
                            items
                                |> List.map
                                    (\i ->
                                        if List.isEmpty (Item.unwrapChildren i.children) then
                                            0

                                        else
                                            Item.getChildrenCount i
                                    )
                                |> List.maximum
                                |> Maybe.withDefault 0

                        svgHeight =
                            (model.settings.size.height
                                + Constants.itemSpan
                            )
                                * (maxChildrenCount
                                    + 2
                                  )
                    in
                    ( svgWidth + Constants.itemSpan, svgHeight + Constants.itemSpan )

                Diagram.UserStoryMap ->
                    ( Constants.leftMargin + (model.settings.size.width + Constants.itemMargin * 2) * (List.maximum model.countByTasks |> Maybe.withDefault 1), (model.settings.size.height + Constants.itemMargin) * (List.sum model.countByHierarchy + 2) )

                Diagram.ImpactMap ->
                    ( (model.settings.size.width + 100) * ((model.hierarchy + 1) * 2 + 1) + 100
                    , case List.head model.items of
                        Just head ->
                            Item.getLeafCount head * (model.settings.size.height + 15) * 2

                        Nothing ->
                            0
                    )

                Diagram.GanttChart ->
                    let
                        rootItem =
                            List.head model.items
                                |> Maybe.withDefault Item.emptyItem

                        children =
                            rootItem
                                |> .children
                                |> Item.unwrapChildren

                        nodeCounts =
                            0
                                :: (children
                                        |> List.map
                                            (\i ->
                                                if List.isEmpty (Item.unwrapChildren i.children) then
                                                    0

                                                else
                                                    Item.getChildrenCount i // 2
                                            )
                                        |> scanl1 (+)
                                   )

                        svgHeight =
                            (last nodeCounts |> Maybe.withDefault 1) * Constants.ganttItemSize + List.length children * 2
                    in
                    case extractDateValues rootItem.text of
                        Just ( from, to ) ->
                            let
                                interval =
                                    diff Day utc from to
                            in
                            ( Constants.leftMargin + 20 + Constants.ganttItemSize + interval * Constants.ganttItemSize, svgHeight + Constants.ganttItemSize )

                        Nothing ->
                            ( 0, 0 )
    in
    ( width, height )


calcDistance : ( Float, Float ) -> ( Float, Float ) -> Float
calcDistance ( x1, y1 ) ( x2, y2 ) =
    sqrt (((x2 - x1) ^ 2) + ((y2 - y1) ^ 2))


getSpacePrefix : String -> String
getSpacePrefix text =
    (text
        |> String.toList
        |> takeWhile (\c -> c == ' ')
        |> List.length
        |> String.repeat
    )
        " "
