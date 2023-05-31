module Views.Diagram.Kanban exposing (docs, view)

import Constants
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Models.Diagram exposing (SelectedItem, SelectedItemInfo)
import Models.Diagram.Data as DiagramData
import Models.Diagram.Kanban as Kanban exposing (Card(..), Kanban(..), KanbanList(..))
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Type as DiagramType
import Models.Item as Item exposing (Item)
import Models.Position exposing (Position)
import Models.Property as Property exposing (Property)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Views.Diagram.Card as Card
import Views.Diagram.Views as Views
import Views.Empty as Empty


view :
    { data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
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
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
kanbanView { settings, property, selectedItem, kanban, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        height : Int
        height =
            Kanban.getCardCount kanban * (settings.size.height + Constants.itemMargin) + Constants.itemMargin

        listWidth : Int
        listWidth =
            settings.size.width + Constants.itemMargin * 3

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
    , dragStart : Views.DragStart msg
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
            , SvgAttr.fill settings.color.label
            , SvgAttr.fontSize "16"
            , SvgAttr.fontWeight "bold"
            ]
            [ Svg.text name ]
            :: Svg.line
                [ SvgAttr.x1 <| String.fromInt <| posX + settings.size.width + 8 + Constants.itemMargin
                , SvgAttr.y1 "0"
                , SvgAttr.x2 <| String.fromInt <| posX + settings.size.width + 8 + Constants.itemMargin
                , SvgAttr.y2 <| String.fromInt <| height + Constants.itemMargin
                , SvgAttr.stroke settings.color.line
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
                            , posY + kanbanMargin + Constants.itemMargin + (settings.size.height + Constants.itemMargin) * i
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
