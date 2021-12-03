module Views.Diagram.Kanban exposing (view)

import Constants
import Models.Diagram as Diagram exposing (Model, Msg, SelectedItem, Settings, fontStyle)
import Models.Diagram.Kanban as Kanban exposing (Card(..), Kanban(..), KanbanList(..))
import Models.Position exposing (Position)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Views.Diagram.Views as Views
import Views.Empty as Empty


kanbanMargin : Int
kanbanMargin =
    24


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.Kanban k ->
            Svg.g
                []
                [ Lazy.lazy3 kanbanView model.settings model.selectedItem k ]

        _ ->
            Empty.view


kanbanView : Settings -> SelectedItem -> Kanban -> Svg Msg
kanbanView settings selectedItem kanban =
    let
        (Kanban lists) =
            kanban

        listWidth =
            settings.size.width + Constants.itemMargin * 3

        height =
            Kanban.getCardCount kanban * (settings.size.height + Constants.itemMargin) + Constants.itemMargin
    in
    Svg.g []
        (List.indexedMap
            (\i list ->
                listView settings height ( i * listWidth + Constants.itemMargin, 0 ) selectedItem list
            )
            lists
        )


listView : Settings -> Int -> Position -> SelectedItem -> KanbanList -> Svg Msg
listView settings height ( posX, posY ) selectedItem (KanbanList name cards) =
    Svg.g []
        (Svg.text_
            [ SvgAttr.x <| String.fromInt <| posX + 8
            , SvgAttr.y <| String.fromInt <| posY + kanbanMargin
            , SvgAttr.fontFamily (fontStyle settings)
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
                    Lazy.lazy Views.card
                        { settings = settings
                        , position =
                            ( posX
                            , posY + kanbanMargin + Constants.itemMargin + (settings.size.height + Constants.itemMargin) * i
                            )
                        , selectedItem = selectedItem
                        , item = item
                        , canMove = True
                        }
                )
                cards
        )
