module Models.Views.GanttChart exposing (GanttChart, from)

import Data.Item as Item exposing (Item, Items)
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
            Section (Item.getText item) taskItems
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
    Maybe.map (\( f, t ) -> Task (Item.getText item) (Schedule f t (diff f t))) schedule
