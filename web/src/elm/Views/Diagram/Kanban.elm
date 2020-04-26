module Views.Diagram.Kanban exposing (view)

import Constants
import Data.Item exposing (Item)
import Data.Position exposing (Position)
import Models.Diagram exposing (Model, Msg(..), Settings, fontStyle)
import Models.Views.Kanban as Kanban exposing (Card(..), Kanban(..), KanbanList(..))
import String
import Svg exposing (Svg, g, line, text, text_)
import Svg.Attributes exposing (fill, fontFamily, fontSize, fontWeight, stroke, strokeWidth, transform, x, x1, x2, y, y1, y2)
import Views.Diagram.Views as Views


kanbanMargin : Int
kanbanMargin =
    24


view : Model -> Svg Msg
view model =
    g
        [ transform
            ("translate("
                ++ String.fromFloat
                    (if isInfinite <| model.x then
                        0

                     else
                        model.x
                    )
                ++ ","
                ++ String.fromFloat
                    (if isInfinite <| model.y then
                        0

                     else
                        model.y
                    )
                ++ ")"
            )
        , fill model.settings.backgroundColor
        ]
        [ kanbanView model.settings model.selectedItem (Kanban.fromItems model.items) ]


kanbanView : Settings -> Maybe Item -> Kanban -> Svg Msg
kanbanView settings selectedItem kanban =
    let
        (Kanban lists) =
            kanban

        listWidth =
            settings.size.width + Constants.itemMargin * 3

        height =
            Kanban.getCardCount kanban * (settings.size.height + Constants.itemMargin) + Constants.itemMargin
    in
    g []
        (List.indexedMap
            (\i list ->
                listView settings height ( i * listWidth + Constants.itemMargin, 0 ) selectedItem list
            )
            lists
        )


listView : Settings -> Int -> Position -> Maybe Item -> KanbanList -> Svg Msg
listView settings height ( posX, posY ) selectedItem (KanbanList name cards) =
    g []
        (text_
            [ x <| String.fromInt <| posX + 8
            , y <| String.fromInt <| posY + kanbanMargin
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "16"
            , fontWeight "bold"
            ]
            [ text name ]
            :: line
                [ x1 <| String.fromInt <| posX + settings.size.width + 8 + Constants.itemMargin
                , y1 "0"
                , x2 <| String.fromInt <| posX + settings.size.width + 8 + Constants.itemMargin
                , y2 <| String.fromInt <| height + Constants.itemMargin
                , stroke settings.color.line
                , strokeWidth "3"
                ]
                []
            :: List.indexedMap
                (\i (Card item) ->
                    Views.cardView settings
                        ( posX
                        , posY + kanbanMargin + Constants.itemMargin + (settings.size.height + Constants.itemMargin) * i
                        )
                        selectedItem
                        item
                )
                cards
        )
