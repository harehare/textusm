module Views.Diagram.FreeForm exposing (..)

import Data.Item as Item
import Models.Diagram as Diagram exposing (Model, Msg(..))
import Models.Views.FreeForm as FreeForm
import Svg exposing (Svg)
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.FreeForm f ->
            let
                moveingItem =
                    case model.moveState of
                        Diagram.ItemMove target ->
                            case target of
                                Diagram.ItemTarget item ->
                                    Just item

                                _ ->
                                    Nothing

                        _ ->
                            Nothing
            in
            Svg.g []
                (Item.indexedMap
                    (\i item ->
                        Views.card
                            { settings = model.settings
                            , position =
                                ( 16 + modBy 4 i * (model.settings.size.width + 16)
                                , (i // 4) * (model.settings.size.height + 16)
                                )
                            , selectedItem = model.selectedItem
                            , item =
                                moveingItem
                                    |> Maybe.map
                                        (\v ->
                                            if Item.getLineNo v == Item.getLineNo item then
                                                v

                                            else
                                                item
                                        )
                                    |> Maybe.withDefault item
                            , canMove = True
                            }
                    )
                    (FreeForm.getItems f)
                )

        _ ->
            Empty.view
