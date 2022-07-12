module Style.Style exposing
    ( borderBottom05
    , borderContent
    , borderRight05
    , borderTop05
    , breakWord
    , button
    , dialogBackdrop
    , emptyContent
    , flexCenter
    , flexHCenter
    , flexSpace
    , flexStart
    , full
    , fullScreen
    , gap4
    , hContent
    , hMain
    , hMobileContent
    , heightAuto
    , heightFull
    , heightScreen
    , inputLight
    , label
    , m0
    , m1
    , mSm
    , mbSm
    , ml2
    , mlSm
    , mlXs
    , mrMd
    , mrSm
    , mt0
    , mtXs
    , objectFitCover
    , padding3
    , paddingMd
    , paddingRightSm
    , paddingSm
    , paddingXs
    , rounded
    , roundedFull
    , roundedNone
    , roundedSm
    , shadowNone
    , shadowSm
    , submit
    , wMenu
    , widthAuto
    , widthFull
    , widthScreen
    )

import Css
    exposing
        ( active
        , after
        , alignItems
        , auto
        , backgroundColor
        , border3
        , borderBottom3
        , borderBox
        , borderRadius
        , borderRight3
        , borderStyle
        , borderTop3
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


borderBottom05 : Css.Style
borderBottom05 =
    borderBottom3 (px 0.5) solid (rgba 0 0 0 0.1)


borderContent : Css.Style
borderContent =
    border3 (px 1) solid (rgba 0 0 0 0.1)


borderRight05 : Css.Style
borderRight05 =
    borderRight3 (px 0.5) solid (rgba 0 0 0 0.1)


borderTop05 : Css.Style
borderTop05 =
    borderTop3 (px 0.5) solid (rgba 0 0 0 0.1)


breakWord : Css.Style
breakWord =
    property "word-wrap" "break-word"


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


emptyContent : Css.Style
emptyContent =
    property "content" "\"\""


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


flexSpace : Css.Style
flexSpace =
    Css.batch [ displayFlex, alignItems center, justifyContent spaceBetween ]


flexStart : Css.Style
flexStart =
    Css.batch
        [ displayFlex
        , alignItems start
        , justifyContent start
        ]


full : Css.Style
full =
    Css.batch
        [ width <| pct 100
        , height <| pct 100
        ]


fullScreen : Css.Style
fullScreen =
    Css.batch
        [ width <| vw 100
        , height <| vh 100
        ]


gap4 : Css.Style
gap4 =
    property "gap" "1rem"


hContent : Css.Style
hContent =
    height <| calc (vh 100) minus (px 72)


hMain : Css.Style
hMain =
    height <| calc (vh 100) minus (px 90)


hMobileContent : Css.Style
hMobileContent =
    height <| calc (vh 100) minus (px 128)


heightAuto : Css.Style
heightAuto =
    height <| auto


heightFull : Css.Style
heightFull =
    height <| pct 100


heightScreen : Css.Style
heightScreen =
    height <| vw 100


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


label : Css.Style
label =
    Css.batch [ Text.xl, Font.fontSemiBold ]


m0 : Css.Style
m0 =
    margin <| px 0


m1 : Css.Style
m1 =
    margin <| rem 0.25


mSm : Css.Style
mSm =
    margin <| px 8


mbSm : Css.Style
mbSm =
    marginBottom <| px 8


ml2 : Css.Style
ml2 =
    marginLeft <| rem 0.5


mlSm : Css.Style
mlSm =
    marginLeft <| px 8


mlXs : Css.Style
mlXs =
    marginLeft <| px 4


mrMd : Css.Style
mrMd =
    marginRight <| px 16


mrSm : Css.Style
mrSm =
    marginRight <| px 8


mt0 : Css.Style
mt0 =
    marginTop zero


mtXs : Css.Style
mtXs =
    marginTop <| px 4


objectFitCover : Css.Style
objectFitCover =
    property "object-fit" "cover"


padding3 : Css.Style
padding3 =
    padding <| rem 0.75


paddingMd : Css.Style
paddingMd =
    padding <| px 16


paddingRightSm : Css.Style
paddingRightSm =
    paddingRight <| px 8


paddingSm : Css.Style
paddingSm =
    padding <| px 8


paddingXs : Css.Style
paddingXs =
    padding <| px 4


rounded : Css.Style
rounded =
    borderRadius <| rem 0.25


roundedFull : Css.Style
roundedFull =
    borderRadius <| px 9999


roundedNone : Css.Style
roundedNone =
    borderRadius <| px 0


roundedSm : Css.Style
roundedSm =
    borderRadius <| rem 0.125


shadowNone : Css.Style
shadowNone =
    boxShadow3 (px 0) (px 0) (hex "#000000")


shadowSm : Css.Style
shadowSm =
    boxShadow5 (px 0) (px 1) (px 2) (px 0) (rgba 0 0 0 0.05)


submit : Css.Style
submit =
    Css.batch
        [ button
        , Css.batch
            [ Color.bgAccent
            , width <| px 80
            , display inlineBlock
            , textAlign center
            , borderStyle none
            ]
        ]


wMenu : Css.Style
wMenu =
    width <| px 40


widthAuto : Css.Style
widthAuto =
    width <| auto


widthFull : Css.Style
widthFull =
    width <| pct 100


widthScreen : Css.Style
widthScreen =
    width <| vw 100
