module Diagram.View.Grid exposing (view)

import Css exposing (backgroundColor)
import Diagram.Types exposing (SelectedItem, SelectedItemInfo)
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Settings as DiagramSettings
import Diagram.View.Card as Card
import Diagram.View.Views as Views
import Events
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Types.Color as Color
import Types.FontSize as FontSize
import Types.Item as Item exposing (Item)
import Types.Position exposing (Position)
import Types.Property exposing (Property)


view :
    { settings : DiagramSettings.Settings
    , property : Property
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
view { settings, property, position, selectedItem, item, onEditSelectedItem, onEndEditSelectedItem, onSelect } =
    let
        ( forgroundColor, backgroundColor ) =
            Views.getItemColor settings property item

        ( posX, posY ) =
            position

        view_ : Svg msg
        view_ =
            Svg.g
                [ Events.onClickStopPropagation <|
                    onSelect <|
                        Just
                            { item = item
                            , position = ( posX, posY + CardSize.toInt settings.size.height )
                            , displayAllMenu = True
                            }
                ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt <| CardSize.toInt settings.size.width
                    , SvgAttr.height <| String.fromInt <| CardSize.toInt settings.size.height - 1
                    , SvgAttr.x (String.fromInt posX)
                    , SvgAttr.y (String.fromInt posY)
                    , SvgAttr.fill <| Color.toString backgroundColor
                    , SvgAttr.stroke <| Color.toString settings.color.line
                    , SvgAttr.strokeWidth "1"
                    ]
                    []
                , Card.text
                    { settings = settings
                    , position = ( posX, posY )
                    , size = ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height )
                    , color = forgroundColor
                    , fontSize = Item.getFontSize item |> Maybe.withDefault FontSize.default
                    , item = item
                    }
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.eq item_ item then
                Svg.g []
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt <| CardSize.toInt settings.size.width
                        , SvgAttr.height <| String.fromInt <| CardSize.toInt settings.size.height - 1
                        , SvgAttr.x (String.fromInt posX)
                        , SvgAttr.y (String.fromInt posY)
                        , SvgAttr.stroke "rgba(0, 0, 0, 0.1)"
                        , SvgAttr.fill <| Color.toString backgroundColor
                        , SvgAttr.stroke <| Color.toString settings.color.line
                        , SvgAttr.strokeWidth "1"
                        , SvgAttr.class "ts-grid"
                        ]
                        []
                    , Views.inputView
                        { color = forgroundColor
                        , fontSize = Item.getFontSize item |> Maybe.withDefault FontSize.default
                        , item = item_
                        , position = ( posX, posY )
                        , settings = settings
                        , size = ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height )
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        }
                    ]

            else
                view_

        Nothing ->
            view_
