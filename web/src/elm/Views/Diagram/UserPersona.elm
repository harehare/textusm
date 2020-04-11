module Views.Diagram.UserPersona exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg(..))
import Models.Views.UserPersona as UserPersona exposing (UserPersonaItem(..))
import String
import Svg exposing (Svg, g)
import Svg.Attributes exposing (fill, transform)
import Utils
import Views.Diagram.Views as Views


view : Model -> Svg Msg
view model =
    let
        itemHeight =
            Basics.max Constants.itemHeight <| Utils.getCanvasHeight model

        userPersona =
            UserPersona.fromItems model.items

        (UserPersonaItem name) =
            userPersona.name

        (UserPersonaItem whoAmI) =
            userPersona.whoAmI

        (UserPersonaItem threeReasonsToUseYourProduct) =
            userPersona.threeReasonsToUseYourProduct

        (UserPersonaItem threeReasonsToBuyYourProduct) =
            userPersona.threeReasonsToBuyYourProduct

        (UserPersonaItem myInterests) =
            userPersona.myInterests

        (UserPersonaItem myPersonality) =
            userPersona.myPersonality

        (UserPersonaItem mySkils) =
            userPersona.mySkils

        (UserPersonaItem myDreams) =
            userPersona.myDreams

        (UserPersonaItem myRelationshipWithTechnology) =
            userPersona.myRelationshipWithTechnology
    in
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
        [ Views.canvasImageView model.settings
            ( Constants.itemWidth, itemHeight )
            ( 0, 0 )
            name
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, 0 )
            model.selectedItem
            whoAmI
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 1.5 - 5), itemHeight )
            ( round (toFloat Constants.itemWidth * 2) - 10, 0 )
            model.selectedItem
            threeReasonsToUseYourProduct
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 1.5), itemHeight )
            ( round (toFloat Constants.itemWidth * 3.5) - 20, 0 )
            model.selectedItem
            threeReasonsToBuyYourProduct
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( 0, itemHeight - 5 )
            model.selectedItem
            myInterests
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, itemHeight - 5 )
            model.selectedItem
            myPersonality
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 2 - 10, itemHeight - 5 )
            model.selectedItem
            mySkils
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
            model.selectedItem
            myDreams
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 4 - 20, itemHeight - 5 )
            model.selectedItem
            myRelationshipWithTechnology
        ]
