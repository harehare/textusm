module Views.Diagram.Grid exposing (view)

import Css
    exposing
        ( backgroundColor
        , property
        )
import Events
import Models.Color as Color
import Models.Diagram exposing (Msg(..), SelectedItem)
import Models.DiagramSettings as DiagramSettings
import Models.FontSize as FontSize
import Models.Item as Item exposing (Item)
import Models.Position exposing (Position)
import Models.Property exposing (Property)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Card as Card
import Views.Diagram.Views as Views


view : DiagramSettings.Settings -> Property -> Position -> SelectedItem -> Item -> Svg Msg
view settings property ( posX, posY ) selectedItem item =
    let
        ( forgroundColor, backgroundColor ) =
            Views.getItemColor settings property item

        view_ : Svg Msg
        view_ =
            Svg.g [ Events.onClickStopPropagation <| Select <| Just { item = item, position = ( posX, posY + settings.size.height ), displayAllMenu = True } ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt settings.size.width
                    , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                    , SvgAttr.x (String.fromInt posX)
                    , SvgAttr.y (String.fromInt posY)
                    , SvgAttr.fill <| Color.toString backgroundColor
                    , SvgAttr.stroke settings.color.line
                    , SvgAttr.strokeWidth "1"
                    ]
                    []
                , Card.text settings
                    ( posX, posY )
                    ( settings.size.width, settings.size.height )
                    forgroundColor
                    (Item.getFontSize item |> Maybe.withDefault FontSize.default)
                    item
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt settings.size.width
                        , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                        , SvgAttr.x (String.fromInt posX)
                        , SvgAttr.y (String.fromInt posY)
                        , SvgAttr.stroke "rgba(0, 0, 0, 0.1)"
                        , SvgAttr.fill <| Color.toString backgroundColor
                        , SvgAttr.stroke settings.color.line
                        , SvgAttr.strokeWidth "1"
                        , SvgAttr.class "ts-grid"
                        ]
                        []
                    , Views.inputView
                        { settings = settings
                        , fontSize = Item.getFontSize item |> Maybe.withDefault FontSize.default
                        , position = ( posX, posY )
                        , size = ( settings.size.width, settings.size.height )
                        , color = forgroundColor
                        , item = item_
                        }
                    ]

            else
                view_

        Nothing ->
            view_
