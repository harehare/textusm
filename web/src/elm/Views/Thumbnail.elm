module Views.Thumbnail exposing (view)

import Html exposing (Html, div)
import Html.Attributes as Attr
import Html.Events.Extra.Mouse as Mouse
import Models.Diagram exposing (Model, Msg(..))
import Models.DiagramType exposing (DiagramType(..))
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Svg.Lazy exposing (..)
import Views.Diagram.BusinessModelCanvas as BusinessModelCanvas
import Views.Diagram.FourLs as FourLs
import Views.Diagram.Kpt as Kpt
import Views.Diagram.Markdown as Markdown
import Views.Diagram.MindMap as MindMap
import Views.Diagram.OpportunityCanvas as OpportunityCanvas
import Views.Diagram.StartStopContinue as StartStopContinue
import Views.Diagram.UserPersona as UserPersona
import Views.Diagram.UserStoryMap as UserStoryMap


view : Model -> DiagramType -> ( String, String ) -> Html Msg
view model diagramType ( svgWidth, svgHeight ) =
    let
        baseWidth =
            toFloat <| Maybe.withDefault 0 <| String.toInt <| svgWidth

        baseHeight =
            toFloat <| Maybe.withDefault 0 <| String.toInt <| svgHeight

        rate =
            if baseWidth > baseHeight then
                baseHeight / baseWidth

            else if baseHeight > baseWidth then
                baseWidth / baseHeight

            else
                1

        mainSvg =
            case diagramType of
                UserStoryMap ->
                    lazy UserStoryMap.view model

                BusinessModelCanvas ->
                    lazy BusinessModelCanvas.view model

                OpportunityCanvas ->
                    lazy OpportunityCanvas.view model

                FourLs ->
                    lazy FourLs.view model

                StartStopContinue ->
                    lazy StartStopContinue.view model

                Kpt ->
                    lazy Kpt.view model

                UserPersona ->
                    lazy UserPersona.view model

                Markdown ->
                    lazy Markdown.view model

                MindMap ->
                    lazy MindMap.view model
        newHeight =
            String.fromFloat <| 50 * rate
    in
    div
        [ Attr.class "thumbnail"
        ]
        [ svg
            [ width "50"
            , height newHeight
            , viewBox ("0 0 " ++ svgWidth ++ " " ++ svgHeight)
            , Attr.style "background-color" "transparent"
            ]
            [ mainSvg ]
        ]
