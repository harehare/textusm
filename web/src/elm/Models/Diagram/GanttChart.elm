module Models.Diagram.GanttChart exposing (From, GanttChart(..), Schedule(..), Section(..), Task(..), Title, To, from, sectionSchedule)

import Basics.Extra as BasicEx
import List
import List.Extra as ListEx
import Maybe.Extra as MaybeEx
import Models.Item as Item exposing (Item, Items)
import Time exposing (Month(..), Posix)
import Time.Extra as TimeEx exposing (Interval(..))


type GanttChart
    = GanttChart Schedule (List Section)


type Schedule
    = Schedule From To Int


type alias From =
    Posix


type alias To =
    Posix


type alias Title =
    String


type Section
    = Section Title (List (Maybe Task))


type Task
    = Task Title Schedule


diff : From -> To -> Int
diff fromDate toDate =
    TimeEx.diff Day Time.utc fromDate toDate


sectionSchedule : Section -> Schedule
sectionSchedule (Section _ tasks) =
    let
        ( sectionFrom, sectionTo ) =
            tasks
                |> List.foldl
                    (\task ( sf, st ) ->
                        case task of
                            Nothing ->
                                ( sf, st )

                            Just (Task _ (Schedule f t _)) ->
                                ( if sf > Time.posixToMillis f then
                                    Time.posixToMillis <| f

                                  else
                                    sf
                                , if st < Time.posixToMillis t then
                                    Time.posixToMillis <| t

                                  else
                                    st
                                )
                    )
                    ( BasicEx.maxSafeInteger, 0 )
                |> Tuple.mapBoth Time.millisToPosix Time.millisToPosix
    in
    Schedule sectionFrom sectionTo (diff sectionFrom sectionTo)


stringToPosix : String -> Maybe Posix
stringToPosix str =
    let
        tokens : List String
        tokens =
            String.split "-" str

        year : Maybe Int
        year =
            ListEx.getAt 0 tokens
                |> Maybe.andThen
                    (\v ->
                        if String.length v == 4 then
                            String.toInt v

                        else
                            Nothing
                    )

        month : Maybe Month
        month =
            ListEx.getAt 1 tokens
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

        day : Maybe Int
        day =
            ListEx.getAt 2 tokens
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
                                        Just <| TimeEx.partsToPosix Time.utc (TimeEx.Parts yearValue monthValue dayValue 0 0 0 0)
                                    )
                        )
            )


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


extractDateValues : String -> Maybe ( Posix, Posix )
extractDateValues s =
    let
        rangeValues : List String
        rangeValues =
            String.split " " (String.trim s)

        fromDate : Maybe Posix
        fromDate =
            ListEx.getAt 0 rangeValues
                |> Maybe.andThen
                    (\vv ->
                        stringToPosix (String.trim vv)
                    )

        toDate : Maybe Posix
        toDate =
            ListEx.getAt 1 rangeValues
                |> Maybe.andThen
                    (\vv ->
                        stringToPosix (String.trim vv)
                    )
    in
    fromDate
        |> Maybe.andThen
            (\f ->
                toDate
                    |> Maybe.andThen
                        (\to ->
                            Just ( f, to )
                        )
            )


from : Items -> Maybe GanttChart
from items =
    let
        rootItem : Item
        rootItem =
            Item.head items |> Maybe.withDefault Item.new
    in
    Item.getText rootItem
        |> extractDateValues
        |> Maybe.map
            (\( f, t ) ->
                let
                    sectionList : List Section
                    sectionList =
                        Item.getChildren rootItem
                            |> Item.unwrapChildren
                            |> sectionFromItems
                in
                GanttChart (Schedule f t <| diff f t) sectionList
            )


sectionFromItems : Items -> List Section
sectionFromItems items =
    Item.map
        (\item ->
            let
                taskItems : List (Maybe Task)
                taskItems =
                    Item.getChildren item
                        |> Item.unwrapChildren
                        |> Item.map taskFromItem
                        |> List.filter MaybeEx.isJust
            in
            Section (String.trim <| Item.getText item) taskItems
        )
        items


taskFromItem : Item -> Maybe Task
taskFromItem item =
    let
        schedule : Maybe ( Posix, Posix )
        schedule =
            Item.getChildren item
                |> Item.unwrapChildren
                |> Item.head
                |> Maybe.withDefault Item.new
                |> Item.getText
                |> extractDateValues
    in
    Maybe.map (\( f, t ) -> Task (String.trim <| Item.getText item) (Schedule f t (diff f t))) schedule
