module Style.Text exposing (base, lg, sm, xl, xl2, xs)

import Css exposing (fontSize, lineHeight, rem)


xs : Css.Style
xs =
    Css.batch
        [ fontSize <| rem 0.75
        , lineHeight <| rem 1
        ]


sm : Css.Style
sm =
    Css.batch
        [ fontSize <| rem 0.875
        , lineHeight <| rem 1.25
        ]


base : Css.Style
base =
    Css.batch
        [ fontSize <| rem 1
        , lineHeight <| rem 1.5
        ]


lg : Css.Style
lg =
    Css.batch
        [ fontSize <| rem 1.125
        , lineHeight <| rem 1.75
        ]


xl : Css.Style
xl =
    Css.batch
        [ fontSize <| rem 1.25
        , lineHeight <| rem 1.75
        ]


xl2 : Css.Style
xl2 =
    Css.batch
        [ fontSize <| rem 1.5
        , lineHeight <| rem 2
        ]
