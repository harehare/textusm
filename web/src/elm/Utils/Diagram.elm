module Utils.Diagram exposing (getCanvasHeight, getCanvasSize, getSpacePrefix)

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


getCanvasHeight : DiagramModel.Settings -> Items -> Int
getCanvasHeight settings items =
    let
        taskCount =
            Item.map (\i -> Item.getChildren i |> Item.unwrapChildren |> Item.length) items
                |> List.maximum
    in
    (settings.size.height + Constants.itemMargin) * (taskCount |> Maybe.withDefault 1) + 50


getCanvasSize : DiagramModel.Model -> ( Int, Int )
getCanvasSize model =
    let
        ( width, height ) =
            case model.diagramType of
                Diagram.Fourls ->
                    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.largeItemHeight (getCanvasHeight model.settings model.items) * 2 + 50 )

                Diagram.EmpathyMap ->
                    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.itemHeight (getCanvasHeight model.settings model.items) * 2 + 50 )

                Diagram.OpportunityCanvas ->
                    ( Constants.itemWidth * 5 + 20, Basics.max Constants.itemHeight (getCanvasHeight model.settings model.items) * 3 + 50 )

                Diagram.BusinessModelCanvas ->
                    ( Constants.itemWidth * 5 + 20, Basics.max Constants.itemHeight (getCanvasHeight model.settings model.items) * 3 + 50 )

                Diagram.Kpt ->
                    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.itemHeight (getCanvasHeight model.settings model.items) * 2 + 50 )

                Diagram.StartStopContinue ->
                    ( Constants.itemWidth * 3 + 20, Basics.max Constants.itemHeight (getCanvasHeight model.settings model.items) + 50 )

                Diagram.UserPersona ->
                    ( Constants.itemWidth * 5 + 25, Basics.max Constants.itemHeight (getCanvasHeight model.settings model.items) * 2 + 50 )

                Diagram.ErDiagram ->
                    let
                        ( _, tables ) =
                            ER.from model.items

                        sizeList =
                            List.map
                                (\table ->
                                    let
                                        (Table _ columns _ _) =
                                            table
                                    in
                                    ( ER.tableWidth table, (List.length columns + 1) * Constants.tableRowHeight )
                                )
                                tables

                        ( tableWidth, tableHeight ) =
                            List.foldl
                                (\( w1, h1 ) ( w2, h2 ) ->
                                    ( w1 + w2 + Constants.tableMargin, h1 + h2 + Constants.tableMargin )
                                )
                                ( 0, 0 )
                                sizeList
                    in
                    ( tableWidth, tableHeight )

                Diagram.MindMap ->
                    case model.data of
                        DiagramModel.MindMap items hierarchy ->
                            ( (model.settings.size.width * 2) * (hierarchy * 2) + (model.settings.size.width * 2)
                            , case Item.head items of
                                Just head ->
                                    Item.getLeafCount head * (model.settings.size.height + 24)

                                Nothing ->
                                    0
                            )

                        _ ->
                            ( 0, 0 )

                Diagram.Table ->
                    ( model.settings.size.width * ((model.items |> Item.head |> Maybe.withDefault Item.new |> Item.getChildren |> Item.unwrapChildren |> Item.length) + 1)
                    , model.settings.size.height * Item.length model.items + Constants.itemMargin
                    )

                Diagram.SiteMap ->
                    case model.data of
                        DiagramModel.SiteMap siteMapitems hierarchy ->
                            let
                                items =
                                    siteMapitems
                                        |> Item.head
                                        |> Maybe.withDefault Item.new
                                        |> Item.getChildren
                                        |> Item.unwrapChildren

                                svgWidth =
                                    (model.settings.size.width
                                        + Constants.itemSpan
                                    )
                                        * Item.length items
                                        + Constants.itemSpan
                                        * hierarchy

                                maxChildrenCount =
                                    items
                                        |> Item.map
                                            (\i ->
                                                if Item.isEmpty (Item.unwrapChildren <| Item.getChildren i) then
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

                        _ ->
                            ( 0, 0 )

                Diagram.UserStoryMap ->
                    case model.data of
                        DiagramModel.UserStoryMap userStoryMap ->
                            ( Constants.leftMargin + (model.settings.size.width + Constants.itemMargin * 2) * UserStoryMap.taskCount userStoryMap
                            , (model.settings.size.height + Constants.itemMargin) * (UserStoryMap.storyCount userStoryMap + 2)
                            )

                        _ ->
                            ( 0, 0 )

                Diagram.ImpactMap ->
                    case model.data of
                        DiagramModel.ImpactMap items hierarchy ->
                            ( (model.settings.size.width + 24) * ((hierarchy + 1) * 2) + 100
                            , case Item.head items of
                                Just head ->
                                    Item.getLeafCount head * (model.settings.size.height + 24) * 2

                                Nothing ->
                                    0
                            )

                        _ ->
                            ( 0, 0 )

                Diagram.GanttChart ->
                    let
                        rootItem =
                            Item.head model.items
                                |> Maybe.withDefault Item.new

                        children =
                            rootItem
                                |> Item.getChildren
                                |> Item.unwrapChildren

                        nodeCounts =
                            0
                                :: (children
                                        |> Item.map
                                            (\i ->
                                                if Item.isEmpty (Item.unwrapChildren <| Item.getChildren i) then
                                                    0

                                                else
                                                    Item.getChildrenCount i // 2
                                            )
                                        |> scanl1 (+)
                                   )

                        svgHeight =
                            (last nodeCounts |> Maybe.withDefault 1) * Constants.ganttItemSize + Item.length children * 2
                    in
                    case DateUtils.extractDateValues <| Item.getText rootItem of
                        Just ( from, to ) ->
                            let
                                interval =
                                    diff Day utc from to
                            in
                            ( Constants.leftMargin + 20 + Constants.ganttItemSize + interval * Constants.ganttItemSize, svgHeight + Constants.ganttItemSize )

                        Nothing ->
                            ( 0, 0 )

                Diagram.Kanban ->
                    let
                        kanban =
                            Kanban.from model.items
                    in
                    ( Kanban.getListCount kanban * (model.settings.size.width + Constants.itemMargin * 3), Kanban.getCardCount kanban * (model.settings.size.height + Constants.itemMargin) + Constants.itemMargin * 2 )

                Diagram.SequenceDiagram ->
                    let
                        sequenceDiagram =
                            SequenceDiagram.from model.items

                        diagramWidth =
                            SequenceDiagram.participantCount sequenceDiagram * (model.settings.size.width + Constants.participantMargin) + 8

                        diagramHeight =
                            SequenceDiagram.messageCountAll sequenceDiagram
                                * Constants.messageMargin
                                + model.settings.size.height
                                * 4
                                + Constants.messageMargin
                                + 8
                    in
                    ( diagramWidth, diagramHeight )
    in
    ( width, height )


getSpacePrefix : String -> String
getSpacePrefix text =
    (text
        |> String.toList
        |> takeWhile (\c -> c == ' ')
        |> List.length
        |> String.repeat
    )
        " "
