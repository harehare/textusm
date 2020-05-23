module Views.Diagram.UserPersona exposing (view)

import Constants
import Data.Position as Position
import Models.Diagram as Diagram exposing (Model, Msg(..))
import Models.Views.UserPersona exposing (UserPersonaItem(..))
import String
import Svg exposing (Svg, g)
import Svg.Attributes exposing (fill, style, transform)
import Svg.Lazy exposing (lazy4, lazy5)
import Utils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.UserPersona u ->
            let
                itemHeight =
                    Basics.max Constants.itemHeight <| Utils.getCanvasHeight model.settings model.items

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
            g
                [ transform
                    ("translate("
                        ++ String.fromInt (Position.getX model.position)
                        ++ ","
                        ++ String.fromInt (Position.getY model.position)
                        ++ "), scale("
                        ++ String.fromFloat model.svg.scale
                        ++ ","
                        ++ String.fromFloat model.svg.scale
                        ++ ")"
                    )
                , fill model.settings.backgroundColor
                , if model.moveStart then
                    style "will-change: transform;"

                  else
                    style "will-change: transform;transition: transform 0.15s ease"
                ]
                [ lazy4 Views.canvasImageView
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( 0, 0 )
                    name
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth - 5, 0 )
                    model.selectedItem
                    whoAmI
                , lazy5 Views.canvasView
                    model.settings
                    ( round (toFloat Constants.itemWidth * 1.5 - 5), itemHeight )
                    ( round (toFloat Constants.itemWidth * 2) - 10, 0 )
                    model.selectedItem
                    threeReasonsToUseYourProduct
                , lazy5 Views.canvasView
                    model.settings
                    ( round (toFloat Constants.itemWidth * 1.5), itemHeight )
                    ( round (toFloat Constants.itemWidth * 3.5) - 20, 0 )
                    model.selectedItem
                    threeReasonsToBuyYourProduct
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( 0, itemHeight - 5 )
                    model.selectedItem
                    myInterests
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth - 5, itemHeight - 5 )
                    model.selectedItem
                    myPersonality
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth * 2 - 10, itemHeight - 5 )
                    model.selectedItem
                    mySkils
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
                    model.selectedItem
                    myDreams
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth * 4 - 20, itemHeight - 5 )
                    model.selectedItem
                    myRelationshipWithTechnology
                ]

        _ ->
            Empty.view
