module Data.FontSize exposing (FontSize, decoder, default, fontSize20, fromInt, htmlFontSize, list, svgFontSize, toInt, unwrap)

import Html.Attributes as HtmlAttr
import Json.Decode as D
import Svg
import Svg.Attributes as SvgAttr


type FontSize
    = FontSize Int


default : FontSize
default =
    FontSize 14


fontSize20 : FontSize
fontSize20 =
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


svgFontSize : FontSize -> Svg.Attribute msg
svgFontSize fontSize =
    SvgAttr.fontSize <| String.fromInt <| unwrap <| fontSize


htmlFontSize : FontSize -> Svg.Attribute msg
htmlFontSize fontSize =
    HtmlAttr.style "font-size" <| (fontSize |> unwrap |> String.fromInt) ++ "px"
