module Style.Font exposing (fontBold, fontFamily, fontSemiBold)

import Css exposing (fontFamilies, fontWeight, int, qt)
import Types.Font as Font exposing (Font)


fontBold : Css.Style
fontBold =
    Css.batch
        [ fontWeight <| int 700
        ]


customFontFamily : Font -> Css.Style
customFontFamily font =
    fontFamilies
        [ qt <| Font.name font
        , "apple-system"
        , "BlinkMacSystemFont"
        , "Helvetica Neue"
        , "Hiragino Kaku Gothic ProN"
        , "游ゴシック Medium"
        , "YuGothic"
        , "YuGothicM"
        , "メイリオ"
        , "Meiryo"
        , "sans-serif"
        , "monospace"
        ]


fontFamily : Css.Style
fontFamily =
    customFontFamily (Font.googleFont "Nunito Sans")


fontSemiBold : Css.Style
fontSemiBold =
    Css.batch
        [ fontWeight <| int 600
        ]
