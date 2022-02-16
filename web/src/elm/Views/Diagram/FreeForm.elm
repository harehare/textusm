module Views.Diagram.FreeForm exposing (view)

import Constants
import Models.Diagram as Diagram exposing (Model, MoveState, Msg)
import Models.Diagram.FreeForm as FreeForm exposing (FreeFormItem)
import Models.DiagramData as DiagramData
import Models.Item as Item exposing (Item)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Views.Diagram.Canvas as Canvas
import Views.Diagram.Card as Card
import Views.Diagram.Line as Line
import Views.Diagram.Text as TextView
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        DiagramData.FreeForm f ->
            Svg.g []
                [ Svg.g [] <|
                    List.indexedMap
                        (formView model)
                        (FreeForm.getItems f)
                ]

        _ ->
            Empty.view


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


formView : Model -> Int -> FreeFormItem -> Svg Msg
formView model i item =
    case item of
        FreeForm.HorizontalLine item_ ->
            Line.horizontal
                { settings = model.settings
                , position =
                    ( 16 + modBy 4 i * (model.settings.size.width + 16)
                    , (i // 4) * (model.settings.size.height + 16)
                    )
                , selectedItem = model.selectedItem
                , item =
                    model.moveState
                        |> moveingItem
                        |> Maybe.map
                            (\v ->
                                if Item.getLineNo v == Item.getLineNo item_ then
                                    v

                                else
                                    item_
                            )
                        |> Maybe.withDefault item_
                }

        FreeForm.VerticalLine item_ ->
            Line.vertical
                { settings = model.settings
                , position =
                    ( 16 + modBy 4 i * (model.settings.size.width + 16)
                    , (i // 4) * (model.settings.size.height + 16)
                    )
                , selectedItem = model.selectedItem
                , item =
                    model.moveState
                        |> moveingItem
                        |> Maybe.map
                            (\v ->
                                if Item.getLineNo v == Item.getLineNo item_ then
                                    v

                                else
                                    item_
                            )
                        |> Maybe.withDefault item_
                }

        FreeForm.Card item_ ->
            Svg.g [] <|
                Card.view
                    { settings = model.settings
                    , property = model.property
                    , position =
                        ( 16 + modBy 4 i * (model.settings.size.width + 16)
                        , (i // 4) * (model.settings.size.height + 16)
                        )
                    , selectedItem = model.selectedItem
                    , item =
                        model.moveState
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
                    }
                    :: (Item.indexedMap
                            (\i_ childItem ->
                                Card.view
                                    { settings = model.settings
                                    , property = model.property
                                    , position =
                                        ( 16 + modBy 4 i * (model.settings.size.width + 16)
                                        , (i + i_ + 1) * (model.settings.size.height + 16)
                                        )
                                    , selectedItem = model.selectedItem
                                    , item =
                                        model.moveState
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
                                    }
                            )
                        <|
                            (item_
                                |> Item.getChildren
                                |> Item.unwrapChildren
                            )
                       )

        FreeForm.Canvas item_ ->
            Lazy.lazy6 Canvas.view
                model.settings
                model.property
                ( Constants.itemWidth, Constants.itemHeight )
                ( 0, 0 )
                model.selectedItem
                item_

        FreeForm.Text item_ ->
            TextView.view
                { settings = model.settings
                , property = model.property
                , position =
                    ( 16 + modBy 4 i * (model.settings.size.width + 16)
                    , (i // 4) * (model.settings.size.height + 16)
                    )
                , selectedItem = model.selectedItem
                , item =
                    model.moveState
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
                }
