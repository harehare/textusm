module Style.Style exposing (..)

import Css
    exposing
        ( active
        , after
        , alignItems
        , auto
        , backgroundColor
        , border3
        , borderBox
        , borderRadius
        , boxShadow3
        , boxShadow5
        , boxSizing
        , calc
        , center
        , cursor
        , disabled
        , display
        , displayFlex
        , fixed
        , height
        , hex
        , hover
        , inlineBlock
        , int
        , justifyContent
        , left
        , margin
        , marginBottom
        , marginLeft
        , marginRight
        , marginTop
        , minus
        , none
        , opacity
        , outline
        , padding
        , paddingRight
        , pct
        , pointer
        , position
        , property
        , px
        , relative
        , rem
        , rgba
        , solid
        , spaceBetween
        , start
        , textAlign
        , top
        , transparent
        , vh
        , visibility
        , visible
        , vw
        , width
        , zIndex
        , zero
        )
import Css.Global exposing (class, descendants)
import Style.Color as Color
import Style.Font as Font
import Style.Text as Text


flexCenter : Css.Style
flexCenter =
    Css.batch
        [ displayFlex
        , alignItems center
        , justifyContent center
        ]


flexHCenter : Css.Style
flexHCenter =
    Css.batch [ displayFlex, alignItems center ]


flexStart : Css.Style
flexStart =
    Css.batch
        [ displayFlex
        , alignItems start
        , justifyContent start
        ]


flexSpace : Css.Style
flexSpace =
    Css.batch [ displayFlex, alignItems center, justifyContent spaceBetween ]


widthAuto : Css.Style
widthAuto =
    width <| auto


widthFull : Css.Style
widthFull =
    width <| pct 100


widthScreen : Css.Style
widthScreen =
    width <| vw 100


heightAuto : Css.Style
heightAuto =
    height <| auto


heightFull : Css.Style
heightFull =
    height <| pct 100


heightScreen : Css.Style
heightScreen =
    height <| vw 100


fullScreen : Css.Style
fullScreen =
    Css.batch
        [ width <| vw 100
        , height <| vh 100
        ]


full : Css.Style
full =
    Css.batch
        [ width <| pct 100
        , height <| pct 100
        ]


shadowSm : Css.Style
shadowSm =
    boxShadow5 (px 0) (px 1) (px 2) (px 0) (rgba 0 0 0 0.05)


shadowNone : Css.Style
shadowNone =
    boxShadow3 (px 0) (px 0) (hex "#000000")


roundedNone : Css.Style
roundedNone =
    borderRadius <| px 0


roundedSm : Css.Style
roundedSm =
    borderRadius <| rem 0.125


rounded : Css.Style
rounded =
    borderRadius <| rem 0.25


roundedFull : Css.Style
roundedFull =
    borderRadius <| px 9999


padding3 : Css.Style
padding3 =
    padding <| rem 0.75


paddingXs : Css.Style
paddingXs =
    padding <| px 4


paddingSm : Css.Style
paddingSm =
    padding <| px 8


paddingMd : Css.Style
paddingMd =
    padding <| px 16


paddingRightSm : Css.Style
paddingRightSm =
    paddingRight <| px 8


m0 : Css.Style
m0 =
    margin <| px 0


m1 : Css.Style
m1 =
    margin <| rem 0.25


mSm : Css.Style
mSm =
    margin <| px 8


mt0 : Css.Style
mt0 =
    marginTop zero


mtXs : Css.Style
mtXs =
    marginTop <| px 4


mrMd : Css.Style
mrMd =
    marginRight <| px 16


mlXs : Css.Style
mlXs =
    marginLeft <| px 4


mlSm : Css.Style
mlSm =
    marginLeft <| px 8


mrSm : Css.Style
mrSm =
    marginRight <| px 8


mbSm : Css.Style
mbSm =
    marginBottom <| px 8


ml2 : Css.Style
ml2 =
    marginLeft <| rem 0.5


emptyContent : Css.Style
emptyContent =
    property "content" "\"\""


gap4 : Css.Style
gap4 =
    property "gap" "1rem"


borderContent : Css.Style
borderContent =
    border3 (px 1) solid (rgba 0 0 0 0.1)


hContent : Css.Style
hContent =
    height <| calc (vh 100) minus (px 72)


hMain : Css.Style
hMain =
    height <| calc (vh 100) minus (px 90)


wMenu : Css.Style
wMenu =
    width <| px 40


inputLight : Css.Style
inputLight =
    Css.batch
        [ Font.fontFamily
        , Color.textDark
        , outline none
        , backgroundColor <| hex "#FEFEFE"
        , roundedSm
        , border3 (px 1) solid transparent
        , padding <| px 8
        , height <| px 32
        , border3 (px 1) solid (hex "#8c9fae")
        , boxSizing borderBox
        , disabled [ backgroundColor <| hex "#cccccc" ]
        ]


button : Css.Style
button =
    Css.batch
        [ padding <| px 8
        , cursor pointer
        , position relative
        , Color.textColor
        , displayFlex
        , alignItems center
        , justifyContent center
        , roundedSm
        , hover
            [ descendants
                [ class "bottom-tooltip"
                    [ visibility visible
                    , opacity <| int 100
                    , Color.textColor
                    ]
                ]
            ]
        , active
            [ after
                [ backgroundColor <| rgba 0 0 0 0.6
                ]
            ]
        ]


submit : Css.Style
submit =
    Css.batch
        [ button
        , Css.batch
            [ Color.bgAccent, width <| px 80, display inlineBlock, textAlign center ]
        ]


label : Css.Style
label =
    Css.batch [ Text.xl, Font.fontSemiBold ]


dialogBackdrop : Css.Style
dialogBackdrop =
    Css.batch
        [ fullScreen
        , backgroundColor <| rgba 0 0 0 0.6
        , position fixed
        , top zero
        , left zero
        , zIndex <| int 100
        ]


objectFitCover : Css.Style
objectFitCover =
    property "object-fit" "cover"


breakWord : Css.Style
breakWord =
    property "word-wrap" "break-word"
