module View.Progress exposing (docs, view)

import Css
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Style.Style as Style
import View.Loading as Loading


view : Html msg
view =
    Html.div
        [ Attr.css
            [ Css.position Css.absolute
            , Css.top <| Css.px 0
            , Css.left <| Css.px 0
            , Style.fullScreen
            , Style.flexCenter
            , Css.zIndex <| Css.int 40
            , Css.backgroundColor <| Css.rgba 39 48 55 0.7
            ]
        ]
        [ Loading.view ]


docs : Chapter x
docs =
    Chapter.chapter "Progress"
        |> Chapter.renderComponentList
            [ ( "progress", view |> Html.toUnstyled )
            ]
