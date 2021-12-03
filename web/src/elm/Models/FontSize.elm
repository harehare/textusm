module Models.FontSize exposing
    ( FontSize
    , cssFontSize
    , decoder
    , default
    , fromInt
    , htmlFontSize
    , lg
    , list
    , svgFontSize
    , svgStyledFontSize
    , toInt
    , unwrap
    , xs
    )

import Css exposing (px)
import Html.Attributes as HtmlAttr
import Json.Decode as D
import Svg
import Svg.Attributes as SvgAttr
import Svg.Styled as SvgStyled
import Svg.Styled.Attributes as SvgStyledAttr


type FontSize
    = FontSize Int


default : FontSize
default =
    FontSize 14


xs : FontSize
xs =
    FontSize 8


lg : FontSize
lg =
    FontSize 20


list : List FontSize
list =
    [ FontSize 8
    , FontSize 9
    , FontSize 10
    , FontSize 11
    , FontSize 12
    , default
    , FontSize 18
    , FontSize 24
    ]


unwrap : FontSize -> Int
unwrap (FontSize fontSize) =
    fontSize


fromInt : Int -> FontSize
fromInt fontSize =
    FontSize fontSize


toInt : FontSize -> Int
toInt (FontSize fontSize) =
    fontSize


decoder : D.Decoder FontSize
decoder =
    D.map FontSize D.int


svgStyledFontSize : FontSize -> SvgStyled.Attribute msg
svgStyledFontSize fontSize =
    SvgStyledAttr.fontSize <| String.fromInt <| unwrap <| fontSize


svgFontSize : FontSize -> Svg.Attribute msg
svgFontSize fontSize =
    SvgAttr.fontSize <| String.fromInt <| unwrap <| fontSize


htmlFontSize : FontSize -> Svg.Attribute msg
htmlFontSize fontSize =
    HtmlAttr.style "font-size" <| (fontSize |> unwrap |> String.fromInt) ++ "px"


cssFontSize : FontSize -> Css.Style
cssFontSize fontSize =
    Css.fontSize <| px <| toFloat (fontSize |> unwrap)
