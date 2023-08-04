module Models.FontSize exposing
    ( FontSize
    , cssFontSize
    , decoder
    , default
    , fromInt
    , lg
    , list
    , s
    , svgStyledFontSize
    , toInt
    , unwrap
    , xs
    )

import Css exposing (px)
import Json.Decode as D
import Svg.Styled as SvgStyled
import Svg.Styled.Attributes as SvgStyledAttr


type FontSize
    = FontSize Int


cssFontSize : FontSize -> Css.Style
cssFontSize fontSize =
    Css.fontSize <| px <| toFloat (fontSize |> unwrap)


decoder : D.Decoder FontSize
decoder =
    D.map FontSize D.int


default : FontSize
default =
    FontSize 12


fromInt : Int -> FontSize
fromInt fontSize =
    FontSize fontSize


lg : FontSize
lg =
    FontSize 20


list : List FontSize
list =
    [ xs
    , FontSize 9
    , s
    , FontSize 11
    , default
    , FontSize 14
    , FontSize 18
    , lg
    , FontSize 24
    ]


svgStyledFontSize : FontSize -> SvgStyled.Attribute msg
svgStyledFontSize fontSize =
    SvgStyledAttr.fontSize <| String.fromInt <| unwrap <| fontSize


toInt : FontSize -> Int
toInt (FontSize fontSize) =
    fontSize


unwrap : FontSize -> Int
unwrap (FontSize fontSize) =
    fontSize


xs : FontSize
xs =
    FontSize 8


s : FontSize
s =
    FontSize 10
