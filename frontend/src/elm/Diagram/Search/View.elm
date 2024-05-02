module Diagram.Search.View exposing (docs, view)

import Css
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css, id, placeholder, value)
import Html.Styled.Events as Events
import Style.Color as ColorStyle
import Style.Style as Style
import Style.Text as TextStyle
import Types.Color as Color
import View.Icon as Icon


view : { query : String, count : Int, searchMsg : String -> msg, closeMsg : msg } -> Html msg
view { query, searchMsg, count, closeMsg } =
    Html.div
        [ css
            [ Style.roundedSm
            , Css.padding4 (Css.px 4) (Css.px 4) (Css.px 4) (Css.px 16)
            , Css.border3 (Css.px 1) Css.solid (Css.rgba 0 0 0 0.1)
            , Style.flexSpace
            , Css.backgroundColor <| Css.hex <| Color.toString Color.white2
            , Css.width <| Css.px 252
            ]
        ]
        [ Html.input
            [ css
                [ Style.inputLight
                , TextStyle.sm
                , Style.paddingXs
                , Css.width <| Css.px 240
                ]
            , id "diagram-search"
            , Events.onInput searchMsg
            , placeholder "Search"
            , value query
            ]
            []
        , Html.div
            [ css [ Css.padding2 (Css.px 8) (Css.px 8), Css.marginTop (Css.px 4), Css.cursor Css.pointer ], Events.onClick closeMsg ]
            [ Icon.clear (Color.toString Color.gray) 20 ]
        , Html.div
            [ css
                [ Css.position Css.absolute
                , Css.right <| Css.px 48
                , Css.top <| Css.px 20
                , TextStyle.xs
                , ColorStyle.textSecondaryColor
                ]
            ]
            [ Html.text <| String.fromInt count
            ]
        ]


docs : Chapter x
docs =
    Chapter.chapter "Search"
        |> Chapter.renderComponent
            (view
                { query = "test"
                , count = 1
                , searchMsg = \_ -> Actions.logAction "onSearch"
                , closeMsg = Actions.logAction "onClose"
                }
                |> Html.toUnstyled
            )
