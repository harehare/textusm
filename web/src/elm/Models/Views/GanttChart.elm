module Models.Views.GanttChart exposing (GanttChart(..), Schedule(..), Section(..), Task(..), from, sectionSchedule)

import Basics.Extra as BasicEx
import Data.Item as Item exposing (Item, Items)
import List
import Maybe.Extra as MaybeEx
import Time exposing (Posix)
import Time.Extra as TimeEx exposing (Interval(..))
import Utils.Date as DateUtils


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


from : Items -> Maybe GanttChart
from items =
    let
        rootItem =
            Item.head items |> Maybe.withDefault Item.new

        sectionList =
            Item.getChildren rootItem
                |> Item.unwrapChildren
                |> sectionFromItems
    in
    Item.getText rootItem
        |> DateUtils.extractDateValues
        |> Maybe.map (\( f, t ) -> GanttChart (Schedule f t <| diff f t) sectionList)


sectionFromItems : Items -> List Section
sectionFromItems items =
    Item.map
        (\item ->
            let
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
        schedule =
            Item.getChildren item
                |> Item.unwrapChildren
                |> Item.head
                |> Maybe.withDefault Item.new
                |> Item.getText
                |> DateUtils.extractDateValues
    in
    Maybe.map (\( f, t ) -> Task (String.trim <| Item.getText item) (Schedule f t (diff f t))) schedule
