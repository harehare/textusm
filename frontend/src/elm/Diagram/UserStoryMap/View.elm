module Diagram.UserStoryMap.View exposing (docs, view)

import Bool.Extra as BoolEx
import Constants
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import Diagram.UserStoryMap.Types as UserStoryMap exposing (CountPerTasks, UserStoryMap)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html
import Html.Styled.Attributes as Attr
import List
import List.Extra as ListEx
import Models.Color as Color
import Models.Diagram exposing (Diagram, SelectedItem, SelectedItemInfo)
import Models.Item as Item exposing (Item, Items)
import Models.Position as Position exposing (Position)
import Models.Property as Property exposing (Property)
import Models.Size as Size
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Keyed as Keyed
import Svg.Styled.Lazy as Lazy
import Views.Diagram.Card as Card
import Views.Diagram.Views as Views
import Views.Empty as Empty


view :
    { data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , diagram : Diagram
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
view { data, settings, diagram, property, selectedItem, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    case data of
        DiagramData.UserStoryMap userStoryMap ->
            Svg.g
                []
                [ Lazy.lazy labelView
                    { settings = settings
                    , width = Size.getWidth diagram.size
                    , userStoryMap = userStoryMap
                    , property = property
                    }
                , Lazy.lazy mainView
                    { settings = settings
                    , selectedItem = selectedItem
                    , items = UserStoryMap.getItems userStoryMap
                    , countByTasks = UserStoryMap.countPerTasks userStoryMap
                    , countByReleaseLevel = UserStoryMap.countPerReleaseLevel userStoryMap
                    , property = property
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                ]

        _ ->
            Empty.view


mainView :
    { settings : DiagramSettings.Settings
    , property : Property
    , selectedItem : SelectedItem
    , items : Items
    , countByTasks : List Int
    , countByReleaseLevel : List Int
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
mainView { settings, property, selectedItem, items, countByTasks, countByReleaseLevel, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    Keyed.node "g"
        []
        (ListEx.zip
            countByTasks
            (Item.unwrap items)
            |> List.indexedMap
                (\i ( count, item ) ->
                    ( "activity-" ++ String.fromInt i
                    , activityView
                        { settings = settings
                        , property = property
                        , verticalCount = List.drop 2 countByReleaseLevel
                        , position = ( Constants.leftMargin + count * (CardSize.toInt settings.size.width + Constants.itemMargin), 10 )
                        , selectedItem = selectedItem
                        , item = item
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                    )
                )
        )


labelView :
    { settings : DiagramSettings.Settings
    , property : Property
    , width : Int
    , userStoryMap : UserStoryMap
    }
    -> Svg msg
labelView { settings, property, width, userStoryMap } =
    let
        posX : Int
        posX =
            16

        hierarchy : Int
        hierarchy =
            UserStoryMap.getHierarchy userStoryMap

        countPerReleaseLevel : CountPerTasks
        countPerReleaseLevel =
            UserStoryMap.countPerReleaseLevel userStoryMap
    in
    Svg.g []
        (([ BoolEx.ifElse
                (Svg.line
                    [ SvgAttr.x1 <| String.fromInt posX
                    , SvgAttr.y1 <| String.fromInt (Constants.itemMargin // 2 + (CardSize.toInt settings.size.height + Constants.itemMargin) * 2)
                    , SvgAttr.x2 <| String.fromInt width
                    , SvgAttr.y2 <| String.fromInt (Constants.itemMargin // 2 + (CardSize.toInt settings.size.height + Constants.itemMargin) * 2)
                    , SvgAttr.stroke <| Color.toString <| DiagramSettings.getLineColor settings property
                    , SvgAttr.strokeWidth "2"
                    ]
                    []
                )
                (Svg.line [] [])
                (hierarchy > 0)
          , BoolEx.ifElse
                (labelTextView settings ( posX, 10 ) (Property.getUserActivity property |> Maybe.withDefault "USER ACTIVITIES"))
                (Svg.g [] [])
                (hierarchy > 0)
          , BoolEx.ifElse
                (labelTextView settings ( posX, CardSize.toInt settings.size.height + 25 ) (Property.getUserTask property |> Maybe.withDefault "USER TASKS"))
                (Svg.g [] [])
                (hierarchy > 0)
          ]
            ++ BoolEx.ifElse
                [ labelTextView settings ( posX, CardSize.toInt settings.size.height * 2 + 50 ) (Property.getUserStory property |> Maybe.withDefault "USER STORIES")
                , labelTextView settings ( posX, CardSize.toInt settings.size.height * 2 + 80 ) (Property.getReleaseLevel 1 property |> Maybe.withDefault "RELEASE 1")
                ]
                [ Svg.g [] [] ]
                (hierarchy > 1)
         )
            ++ (List.range 1 (hierarchy - 2)
                    |> List.concatMap
                        (\xx ->
                            if List.length countPerReleaseLevel - 2 > xx then
                                let
                                    releaseY : Int
                                    releaseY =
                                        Constants.itemMargin
                                            // 2
                                            + Constants.itemMargin
                                            + ((CardSize.toInt settings.size.height + Constants.itemMargin)
                                                * (countPerReleaseLevel
                                                    |> List.take (xx + 2)
                                                    |> List.sum
                                                  )
                                              )
                                            + ((xx - 1) * Constants.itemMargin)
                                in
                                [ Svg.line
                                    [ SvgAttr.x1 <| String.fromInt posX
                                    , SvgAttr.y1 <| String.fromInt releaseY
                                    , SvgAttr.x2 <| String.fromInt width
                                    , SvgAttr.y2 <| String.fromInt releaseY
                                    , SvgAttr.stroke <| Color.toString <| DiagramSettings.getLineColor settings property
                                    , SvgAttr.strokeWidth "2"
                                    ]
                                    []
                                , labelTextView settings ( posX, releaseY + Constants.itemMargin ) (Property.getReleaseLevel (xx + 1) property |> Maybe.withDefault ("RELEASE " ++ String.fromInt (xx + 1)))
                                ]

                            else
                                [ Svg.line [] [] ]
                        )
               )
        )


activityView :
    { settings : DiagramSettings.Settings
    , property : Property
    , verticalCount : List Int
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
activityView { settings, property, verticalCount, position, selectedItem, item, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    Svg.g
        []
    <|
        Lazy.lazy Card.viewWithDefaultColor
            { settings = settings
            , property = property
            , position = position
            , selectedItem = selectedItem
            , item = item
            , canMove = True
            , onEditSelectedItem = onEditSelectedItem
            , onEndEditSelectedItem = onEndEditSelectedItem
            , onSelect = onSelect
            , dragStart = dragStart
            }
            :: (Item.unwrapChildren (Item.getChildren item)
                    |> Item.indexedMap
                        (\i it ->
                            taskView
                                { settings = settings
                                , property = property
                                , verticalCount = verticalCount
                                , position =
                                    ( Position.getX position
                                        + (i * CardSize.toInt settings.size.width)
                                        + (if i > 0 then
                                            i * Constants.itemMargin

                                           else
                                            0
                                          )
                                    , Position.getY position + Constants.itemMargin + CardSize.toInt settings.size.height
                                    )
                                , selectedItem = selectedItem
                                , item = it
                                , onEditSelectedItem = onEditSelectedItem
                                , onEndEditSelectedItem = onEndEditSelectedItem
                                , onSelect = onSelect
                                , dragStart = dragStart
                                }
                        )
               )


taskView :
    { settings : DiagramSettings.Settings
    , property : Property
    , verticalCount : List Int
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
taskView { settings, property, verticalCount, position, selectedItem, item, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        children : Items
        children =
            Item.unwrapChildren <| Item.getChildren item
    in
    Svg.g
        []
    <|
        Lazy.lazy
            Card.viewWithDefaultColor
            { settings = settings
            , property = property
            , position = position
            , selectedItem = selectedItem
            , item = item
            , canMove = True
            , onEditSelectedItem = onEditSelectedItem
            , onEndEditSelectedItem = onEndEditSelectedItem
            , onSelect = onSelect
            , dragStart = dragStart
            }
            :: (children
                    |> Item.indexedMap
                        (\i it ->
                            Svg.g [] <|
                                storyView
                                    { settings = settings
                                    , property = property
                                    , verticalCount = verticalCount
                                    , parentCount = Item.length children
                                    , position =
                                        ( Position.getX position
                                        , Position.getY position
                                            + ((i + 1) * CardSize.toInt settings.size.height)
                                            + (Constants.itemMargin * 2)
                                            + (if i > 0 then
                                                Constants.itemMargin * i

                                               else
                                                0
                                              )
                                        )
                                    , selectedItem = selectedItem
                                    , item = it
                                    , onEditSelectedItem = onEditSelectedItem
                                    , onEndEditSelectedItem = onEndEditSelectedItem
                                    , onSelect = onSelect
                                    , dragStart = dragStart
                                    }
                        )
               )


storyView :
    { settings : DiagramSettings.Settings
    , property : Property
    , verticalCount : List Int
    , parentCount : Int
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> List (Svg msg)
storyView { settings, property, verticalCount, parentCount, position, selectedItem, item, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        itemCount : Int
        itemCount =
            List.head verticalCount |> Maybe.withDefault 1

        children : Items
        children =
            Item.unwrapChildren <| Item.getChildren item

        childrenLength : Int
        childrenLength =
            Item.length children

        tail : List Int
        tail =
            List.tail verticalCount |> Maybe.withDefault []

        storyViewHelper : Items -> List (Svg msg)
        storyViewHelper children_ =
            Item.indexedMap
                (\i it ->
                    storyView
                        { settings = settings
                        , property = property
                        , verticalCount = tail
                        , parentCount = childrenLength
                        , position =
                            ( Position.getX position
                            , Position.getY position
                                + (Basics.max 1 (itemCount - parentCount + i + 1)
                                    * (Constants.itemMargin + CardSize.toInt settings.size.height)
                                  )
                                + Constants.itemMargin
                            )
                        , selectedItem = selectedItem
                        , item = it
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                )
                children_
                |> List.concat
    in
    Lazy.lazy Card.viewWithDefaultColor
        { settings = settings
        , property = property
        , position = position
        , selectedItem = selectedItem
        , item = item
        , canMove = True
        , onEditSelectedItem = onEditSelectedItem
        , onEndEditSelectedItem = onEndEditSelectedItem
        , onSelect = onSelect
        , dragStart = dragStart
        }
        :: storyViewHelper children


labelTextView : DiagramSettings.Settings -> Position -> String -> Svg msg
labelTextView settings ( posX, posY ) t =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.width "100"
        , SvgAttr.height "40"
        , SvgAttr.color <| Color.toString settings.color.label
        , SvgAttr.fontSize "12"
        , SvgAttr.fontWeight "bold"
        ]
        [ Html.div
            [ Attr.style "font-family" (DiagramSettings.fontStyle settings)
            , Attr.style "word-wrap" "break-word"
            ]
            [ Html.text t ]
        ]


docs : Chapter x
docs =
    Chapter.chapter "UserStoryMap"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { data =
                        DiagramData.UserStoryMap <|
                            UserStoryMap.from
                                "test"
                                2
                                (DiagramType.defaultText DiagramType.UserStoryMap |> Item.fromString |> Tuple.second)
                    , settings = DiagramSettings.default
                    , selectedItem = Nothing
                    , property = Property.empty
                    , diagram =
                        { size = ( 100, 100 )
                        , position = ( 0, 0 )
                        , isFullscreen = False
                        }
                    , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                    , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , dragStart = \_ _ -> SvgAttr.style ""
                    }
                ]
                |> Svg.toUnstyled
            )
