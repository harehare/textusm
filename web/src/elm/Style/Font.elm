module Style.Font exposing (..)

import Css exposing (fontFamilies, fontWeight, int, qt)


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


fontBold : Css.Style
fontBold =
    Css.batch
        [ fontWeight <| int 700
        ]


fontSemiBold : Css.Style
fontSemiBold =
    Css.batch
        [ fontWeight <| int 600
        ]
