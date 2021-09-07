module Utils.Diagram exposing (getCanvasHeight, getCanvasSize, getSpacePrefix)

import Constants
import Graphql.Enum.Diagram as Diagram
import Http exposing (Error(..))
import List.Extra as ListEx
import Models.Diagram as DiagramModel
import Models.Diagram.ER as ER exposing (Table(..))
import Models.Diagram.FreeForm as FreeForm
import Models.Diagram.GanttChart exposing (GanttChart(..), Schedule(..), Section(..), Task(..))
import Models.Diagram.Kanban as Kanban
import Models.Diagram.SequenceDiagram as SequenceDiagram
import Models.Diagram.UseCaseDiagram as UseCaseDiagram
    exposing
        ( Actor(..)
        , Relation(..)
        , UseCase(..)
        , UseCaseDiagram(..)
        )
import Models.Diagram.UserStoryMap as UserStoryMap
import Time exposing (Month(..))
import Tuple
import Types.Item as Item exposing (Items)


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
                            ( Constants.leftMargin + (model.settings.size.width + Constants.itemMargin * 2) * (UserStoryMap.taskCount userStoryMap + 1)
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
                    case model.data of
                        DiagramModel.GanttChart (Just gantt) ->
                            let
                                (GanttChart (Schedule _ _ interval) sections) =
                                    gantt

                                nodeCounts =
                                    0
                                        :: (sections
                                                |> List.map
                                                    (\(Section _ tasks) ->
                                                        if List.isEmpty tasks then
                                                            0

                                                        else
                                                            List.length tasks + 1
                                                    )
                                                |> ListEx.scanl1 (+)
                                           )

                                svgHeight =
                                    (ListEx.last nodeCounts |> Maybe.withDefault 1) * Constants.ganttItemSize + List.length sections
                            in
                            ( Constants.leftMargin + 20 + Constants.ganttItemSize + interval * Constants.ganttItemSize, svgHeight + Constants.ganttItemSize )

                        _ ->
                            ( 0, 0 )

                Diagram.Kanban ->
                    case model.data of
                        DiagramModel.Kanban kanban ->
                            ( Kanban.getListCount kanban * (model.settings.size.width + Constants.itemMargin * 3), Kanban.getCardCount kanban * (model.settings.size.height + Constants.itemMargin) + Constants.itemMargin * 2 )

                        _ ->
                            ( 0, 0 )

                Diagram.SequenceDiagram ->
                    case model.data of
                        DiagramModel.SequenceDiagram sequenceDiagram ->
                            let
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

                        _ ->
                            ( 0, 0 )

                Diagram.Freeform ->
                    case model.data of
                        DiagramModel.FreeForm freeForm ->
                            let
                                items =
                                    freeForm
                                        |> FreeForm.unwrap

                                positionList =
                                    List.indexedMap
                                        (\i item ->
                                            let
                                                item_ =
                                                    FreeForm.unwrapItem item

                                                ( offsetX, offsetY ) =
                                                    Item.getOffset item_
                                            in
                                            ( 16 + (modBy 4 i + 1) * (model.settings.size.width + 32)
                                            , (i // 4 + 1) * (model.settings.size.height + 32)
                                            )
                                                |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)
                                        )
                                        items

                                freeFormWidth =
                                    List.map
                                        (\( w, _ ) ->
                                            w
                                        )
                                        positionList
                                        |> List.maximum
                                        |> Maybe.withDefault 0

                                freeFormHeight =
                                    List.map
                                        (\( _, h ) ->
                                            h
                                        )
                                        positionList
                                        |> List.maximum
                                        |> Maybe.withDefault 0
                            in
                            ( freeFormWidth, freeFormHeight )

                        _ ->
                            ( 0, 0 )

                Diagram.UseCaseDiagram ->
                    case model.data of
                        DiagramModel.UseCaseDiagram (UseCaseDiagram actors relations) ->
                            let
                                useCases =
                                    List.map (\(Actor _ a) -> List.map (\(UseCase u) -> u) a) actors
                                        |> List.concat
                                        |> ListEx.uniqueBy Item.getText

                                count =
                                    UseCaseDiagram.allRelationCount useCases relations

                                hierarchy =
                                    UseCaseDiagram.hierarchy useCases relations
                            in
                            ( (hierarchy + 1) * 320, count * 70 )

                        _ ->
                            ( 0, 0 )
    in
    ( width, height )


getSpacePrefix : String -> String
getSpacePrefix text =
    (text
        |> String.toList
        |> ListEx.takeWhile (\c -> c == ' ')
        |> List.length
        |> String.repeat
    )
        " "
