module Views.Diagram.UserPersona exposing (view)

import Constants
import Models.Diagram as Diagram exposing (Model, Msg)
import Models.Diagram.UserPersona exposing (UserPersonaItem(..))
import Svg exposing (Svg)
import Svg.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.UserPersona u ->
            let
                itemHeight =
                    Basics.max Constants.itemHeight <| DiagramUtils.getCanvasHeight model.settings model.items

                (UserPersonaItem name) =
                    u.name

                (UserPersonaItem whoAmI) =
                    u.whoAmI

                (UserPersonaItem threeReasonsToUseYourProduct) =
                    u.threeReasonsToUseYourProduct

                (UserPersonaItem threeReasonsToBuyYourProduct) =
                    u.threeReasonsToBuyYourProduct

                (UserPersonaItem myInterests) =
                    u.myInterests

                (UserPersonaItem myPersonality) =
                    u.myPersonality

                (UserPersonaItem mySkils) =
                    u.mySkils

                (UserPersonaItem myDreams) =
                    u.myDreams

                (UserPersonaItem myRelationshipWithTechnology) =
                    u.myRelationshipWithTechnology
            in
            Svg.g
                []
                [ Lazy.lazy4 Views.canvasImage
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( 0, 0 )
                    name
                , Lazy.lazy5 Views.canvas
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth - 5, 0 )
                    model.selectedItem
                    whoAmI
                , Lazy.lazy5 Views.canvas
                    model.settings
                    ( round (toFloat Constants.itemWidth * 1.5 - 5), itemHeight )
                    ( round (toFloat Constants.itemWidth * 2) - 10, 0 )
                    model.selectedItem
                    threeReasonsToUseYourProduct
                , Lazy.lazy5 Views.canvas
                    model.settings
                    ( round (toFloat Constants.itemWidth * 1.5), itemHeight )
                    ( round (toFloat Constants.itemWidth * 3.5) - 20, 0 )
                    model.selectedItem
                    threeReasonsToBuyYourProduct
                , Lazy.lazy5 Views.canvas
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( 0, itemHeight - 5 )
                    model.selectedItem
                    myInterests
                , Lazy.lazy5 Views.canvas
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth - 5, itemHeight - 5 )
                    model.selectedItem
                    myPersonality
                , Lazy.lazy5 Views.canvas
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth * 2 - 10, itemHeight - 5 )
                    model.selectedItem
                    mySkils
                , Lazy.lazy5 Views.canvas
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
                    model.selectedItem
                    myDreams
                , Lazy.lazy5 Views.canvas
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth * 4 - 20, itemHeight - 5 )
                    model.selectedItem
                    myRelationshipWithTechnology
                ]

        _ ->
            Empty.view
