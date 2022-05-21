module Style.Font exposing (fontBold, fontFamily, fontSemiBold)

import Css exposing (fontFamilies, fontWeight, int, qt)


fontBold : Css.Style
fontBold =
    Css.batch
        [ fontWeight <| int 700
        ]


fontFamily : Css.Style
fontFamily =
    fontFamilies
        [ qt "Nunito Sans"
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
        ]


fontSemiBold : Css.Style
fontSemiBold =
    Css.batch
        [ fontWeight <| int 600
        ]
