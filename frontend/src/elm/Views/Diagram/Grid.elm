module Views.Diagram.Grid exposing (view)

import Css exposing (backgroundColor)
import Events
import Models.Color as Color
import Models.Diagram exposing (SelectedItem, SelectedItemInfo)
import Models.Diagram.Settings as DiagramSettings
import Models.FontSize as FontSize
import Models.Item as Item exposing (Item)
import Models.Position exposing (Position)
import Models.Property exposing (Property)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Card as Card
import Views.Diagram.Views as Views


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
                            , position = ( posX, posY + settings.size.height )
                            , displayAllMenu = True
                            }
                ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt settings.size.width
                    , SvgAttr.height <| String.fromInt <| settings.size.height - 1
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
                    , size = ( settings.size.width, settings.size.height )
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
                        [ SvgAttr.width <| String.fromInt settings.size.width
                        , SvgAttr.height <| String.fromInt <| settings.size.height - 1
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
                        , size = ( settings.size.width, settings.size.height )
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        }
                    ]

            else
                view_

        Nothing ->
            view_
