module Diagram.Kanban.View exposing (docs, view)

import Constants
import Diagram.Kanban.Types as Kanban exposing (Card(..), Kanban(..), KanbanList(..))
import Diagram.Types exposing (SelectedItem, SelectedItemInfo)
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import Diagram.View.Card as Card
import Diagram.View.Views as View
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Types.Color as Color
import Types.Item as Item exposing (Item)
import Types.Position exposing (Position)
import Types.Property as Property exposing (Property)
import View.Empty as Empty


view :
    { data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : View.DragStart msg
    }
    -> Svg msg
view { data, settings, property, selectedItem, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    case data of
        DiagramData.Kanban k ->
            Svg.g
                []
                [ Lazy.lazy kanbanView
                    { settings = settings
                    , property = property
                    , selectedItem = selectedItem
                    , kanban = k
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                ]

        _ ->
            Empty.view


kanbanMargin : Int
kanbanMargin =
    24


kanbanView :
    { settings : DiagramSettings.Settings
    , property : Property
    , selectedItem : SelectedItem
    , kanban : Kanban
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : View.DragStart msg
    }
    -> Svg msg
kanbanView { settings, property, selectedItem, kanban, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        height : Int
        height =
            Kanban.getCardCount kanban * (CardSize.toInt settings.size.height + Constants.itemMargin) + Constants.itemMargin

        listWidth : Int
        listWidth =
            CardSize.toInt settings.size.width + Constants.itemMargin * 3

        (Kanban lists) =
            kanban
    in
    Svg.g []
        (List.indexedMap
            (\i list ->
                listView
                    { settings = settings
                    , property = property
                    , height = height
                    , position = ( i * listWidth + Constants.itemMargin, 0 )
                    , selectedItem = selectedItem
                    , kanban = list
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
            )
            lists
        )


listView :
    { settings : DiagramSettings.Settings
    , property : Property
    , height : Int
    , position : Position
    , selectedItem : SelectedItem
    , kanban : KanbanList
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : View.DragStart msg
    }
    -> Svg msg
listView { settings, property, height, position, selectedItem, kanban, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        (KanbanList name cards) =
            kanban

        ( posX, posY ) =
            position
    in
    Svg.g []
        (Svg.text_
            [ SvgAttr.x <| String.fromInt <| posX + 8
            , SvgAttr.y <| String.fromInt <| posY + kanbanMargin
            , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
            , SvgAttr.fill <| Color.toString settings.color.label
            , SvgAttr.fontSize "16"
            , SvgAttr.fontWeight "bold"
            ]
            [ Svg.text name ]
            :: Svg.line
                [ SvgAttr.x1 <| String.fromInt <| posX + CardSize.toInt settings.size.width + 8 + Constants.itemMargin
                , SvgAttr.y1 "0"
                , SvgAttr.x2 <| String.fromInt <| posX + CardSize.toInt settings.size.width + 8 + Constants.itemMargin
                , SvgAttr.y2 <| String.fromInt <| height + Constants.itemMargin
                , SvgAttr.stroke <| Color.toString settings.color.line
                , SvgAttr.strokeWidth "3"
                ]
                []
            :: List.indexedMap
                (\i (Card item) ->
                    Lazy.lazy Card.viewWithDefaultColor
                        { canMove = True
                        , item = item
                        , position =
                            ( posX
                            , posY + kanbanMargin + Constants.itemMargin + (CardSize.toInt settings.size.height + Constants.itemMargin) * i
                            )
                        , property = property
                        , selectedItem = selectedItem
                        , settings = settings
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                )
                cards
        )


docs : Chapter x
docs =
    Chapter.chapter "Kanban"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { data =
                        DiagramData.Kanban <|
                            Kanban.from <|
                                (DiagramType.defaultText DiagramType.Kanban |> Item.fromString |> Tuple.second)
                    , settings = DiagramSettings.default
                    , selectedItem = Nothing
                    , property = Property.empty
                    , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                    , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , dragStart = \_ _ -> SvgAttr.style ""
                    }
                ]
                |> Svg.toUnstyled
            )
