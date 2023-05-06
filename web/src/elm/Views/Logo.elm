module Views.Logo exposing (docs, view)

import Asset
import Css exposing (cursor, pointer, px, width)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Style.Font as Font
import Style.Style
import Style.Text as Text


view : Html msg
view =
    Html.div [ Attr.css [ cursor pointer ] ]
        [ Html.a
            [ Attr.css [ Style.Style.flexCenter ]
            , Attr.href "https://textusm.com"
            , Attr.target "_black"
            , Attr.rel "noopener noreferrer"
            ]
            [ Html.img
                [ Asset.src Asset.logo
                , Attr.css [ width <| px 24 ]
                , Attr.alt "logo"
                ]
                []
            , Html.span [ Attr.css [ Text.xs, Font.fontBold ] ] [ Html.text "TextUSM" ]
            ]
        ]


docs : Chapter x
docs =
    Chapter.chapter "Logo"
        |> Chapter.renderComponentList
            [ ( "Logo"
              , view
                    |> Html.toUnstyled
              )
            ]
