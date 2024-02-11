module Diagram.FreeForm.View exposing (docs, view)

import Constants
import Diagram.FreeForm.Types as FreeForm exposing (FreeFormItem)
import Diagram.Types as Diagram exposing (MoveState, SelectedItem, SelectedItemInfo)
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.View.Canvas as Canvas
import Diagram.View.Card as Card
import Diagram.View.Line as Line
import Diagram.View.Text as TextView
import Diagram.View.Views as Views
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Types.Item as Item exposing (Item, Items)
import Types.Property as Property exposing (Property)
import Views.Empty as Empty


view :
    { items : Items
    , data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , moveState : MoveState
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
view { data, settings, items, property, selectedItem, moveState, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    case data of
        DiagramData.FreeForm f ->
            Svg.g []
                [ Svg.g [] <|
                    List.indexedMap
                        (formView
                            { items = items
                            , settings = settings
                            , selectedItem = selectedItem
                            , property = property
                            , moveState = moveState
                            , onEditSelectedItem = onEditSelectedItem
                            , onEndEditSelectedItem = onEndEditSelectedItem
                            , onSelect = onSelect
                            , dragStart = dragStart
                            }
                        )
                        (FreeForm.getItems f)
                ]

        _ ->
            Empty.view


formView :
    { items : Items
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , moveState : MoveState
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Int
    -> FreeFormItem
    -> Svg msg
formView { property, moveState, settings, selectedItem, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } i item =
    case item of
        FreeForm.Card item_ ->
            cardView
                { settings = settings
                , selectedItem = selectedItem
                , property = property
                , moveState = moveState
                , i = i
                , item_ = item_
                , onEditSelectedItem = onEditSelectedItem
                , onEndEditSelectedItem = onEndEditSelectedItem
                , onSelect = onSelect
                , dragStart = dragStart
                }

        FreeForm.HorizontalLine item_ ->
            Line.horizontal
                { settings = settings
                , position =
                    ( 16 + modBy 4 i * (CardSize.toInt settings.size.width + 16)
                    , (i // 4) * (CardSize.toInt settings.size.height + 16)
                    )
                , selectedItem = selectedItem
                , item =
                    moveState
                        |> moveingItem
                        |> Maybe.map
                            (\v ->
                                if Item.getLineNo v == Item.getLineNo item_ then
                                    v

                                else
                                    item_
                            )
                        |> Maybe.withDefault item_
                , onSelect = onSelect
                , dragStart = dragStart
                }

        FreeForm.VerticalLine item_ ->
            Line.vertical
                { settings = settings
                , position =
                    ( 16 + modBy 4 i * (CardSize.toInt settings.size.width + 16)
                    , (i // 4) * (CardSize.toInt settings.size.height + 16)
                    )
                , selectedItem = selectedItem
                , item =
                    moveState
                        |> moveingItem
                        |> Maybe.map
                            (\v ->
                                if Item.getLineNo v == Item.getLineNo item_ then
                                    v

                                else
                                    item_
                            )
                        |> Maybe.withDefault item_
                , onSelect = onSelect
                , dragStart = dragStart
                }

        FreeForm.Canvas item_ ->
            Lazy.lazy Canvas.view
                { settings = settings
                , property = property
                , size = ( Constants.itemWidth, Constants.itemHeight )
                , position = ( 0, 0 )
                , selectedItem = selectedItem
                , item = item_
                , onEditSelectedItem = onEditSelectedItem
                , onEndEditSelectedItem = onEndEditSelectedItem
                , onSelect = onSelect
                , dragStart = dragStart
                }

        FreeForm.Text item_ ->
            TextView.view
                { settings = settings
                , property = property
                , position =
                    ( 16 + modBy 4 i * (CardSize.toInt settings.size.width + 16)
                    , (i // 4) * (CardSize.toInt settings.size.height + 16)
                    )
                , selectedItem = selectedItem
                , item =
                    moveState
                        |> moveingItem
                        |> Maybe.map
                            (\v ->
                                if Item.getLineNo v == Item.getLineNo item_ then
                                    v

                                else
                                    item_
                            )
                        |> Maybe.withDefault item_
                , canMove = True
                , onEditSelectedItem = onEditSelectedItem
                , onEndEditSelectedItem = onEndEditSelectedItem
                , onSelect = onSelect
                , dragStart = dragStart
                }


moveingItem : MoveState -> Maybe Item
moveingItem state =
    case state of
        Diagram.ItemMove target ->
            case target of
                Diagram.ItemTarget item ->
                    Just item

                _ ->
                    Nothing

        _ ->
            Nothing


cardView :
    { settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , moveState : MoveState
    , i : Int
    , item_ : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
cardView { selectedItem, settings, property, moveState, i, item_, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    Svg.g [] <|
        Card.viewWithDefaultColor
            { settings = settings
            , property = property
            , position =
                ( 16 + modBy 4 i * (CardSize.toInt settings.size.width + 16)
                , (i // 4) * (CardSize.toInt settings.size.height + 16)
                )
            , selectedItem = selectedItem
            , item =
                moveState
                    |> moveingItem
                    |> Maybe.map
                        (\v ->
                            if Item.getLineNo v == Item.getLineNo item_ then
                                v

                            else
                                item_
                        )
                    |> Maybe.withDefault item_
            , canMove = True
            , onEditSelectedItem = onEditSelectedItem
            , onEndEditSelectedItem = onEndEditSelectedItem
            , onSelect = onSelect
            , dragStart = dragStart
            }
            :: (Item.indexedMap
                    (\i_ childItem ->
                        Card.viewWithDefaultColor
                            { settings = settings
                            , property = property
                            , position =
                                ( 16 + modBy 4 i * (CardSize.toInt settings.size.width + 16)
                                , (i + i_ + 1) * (CardSize.toInt settings.size.height + 16)
                                )
                            , selectedItem = selectedItem
                            , item =
                                moveState
                                    |> moveingItem
                                    |> Maybe.map
                                        (\v ->
                                            if Item.getLineNo v == Item.getLineNo childItem then
                                                v

                                            else
                                                childItem
                                        )
                                    |> Maybe.withDefault childItem
                            , canMove = True
                            , onEditSelectedItem = onEditSelectedItem
                            , onEndEditSelectedItem = onEndEditSelectedItem
                            , onSelect = onSelect
                            , dragStart = dragStart
                            }
                    )
                <|
                    (item_
                        |> Item.getChildren
                        |> Item.unwrapChildren
                    )
               )


docs : Chapter x
docs =
    Chapter.chapter "FreeForm"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { items = Item.empty
                    , data =
                        DiagramData.FreeForm <|
                            FreeForm.from <|
                                Item.fromList
                                    [ Item.new
                                        |> Item.withText "test"
                                        |> Item.withChildren
                                            (Item.childrenFromItems <|
                                                Item.fromList
                                                    [ Item.new
                                                        |> Item.withText "test2"
                                                    ]
                                            )
                                    ]
                    , settings = DiagramSettings.default
                    , selectedItem = Nothing
                    , property = Property.empty
                    , moveState = Diagram.NotMove
                    , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                    , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , dragStart = \_ _ -> SvgAttr.style ""
                    }
                ]
                |> Svg.toUnstyled
            )
