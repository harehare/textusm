module Views.Header exposing (Props, view)

import Asset
import Attributes
import Avatar exposing (Avatar(..))
import Css
    exposing
        ( alignItems
        , borderStyle
        , center
        , color
        , cursor
        , displayFlex
        , ellipsis
        , flexStart
        , focus
        , height
        , hex
        , hidden
        , hover
        , justifyContent
        , left
        , marginLeft
        , marginRight
        , marginTop
        , noWrap
        , none
        , outline
        , overflow
        , padding
        , padding4
        , pct
        , pointer
        , position
        , property
        , px
        , relative
        , rem
        , textAlign
        , textOverflow
        , whiteSpace
        , width
        )
import Events as E
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events
import Html.Styled.Lazy as Lazy
import Json.Decode as D
import Message exposing (Lang)
import Models.Color as Color
import Models.DiagramItem exposing (DiagramItem)
import Models.DiagramLocation as DiagramLocation exposing (DiagramLocation)
import Models.DiagramType as DiagramType
import Models.LoginProvider as LoginProvider exposing (LoginProvider(..))
import Models.Model exposing (Menu(..), Msg(..))
import Models.Page as Page exposing (Page)
import Models.Session as Session exposing (Session)
import Models.Text as Text exposing (Text)
import Models.Title as Title
import Route exposing (Route(..))
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import Views.Empty as Empty
import Views.Icon as Icon
import Views.Menu as Menu
import Views.Tooltip as Tooltip


type alias Props =
    { session : Session
    , page : Page
    , currentDiagram : DiagramItem
    , menu : Maybe Menu
    , currentText : Text
    , lang : Lang
    , route : Route
    , prevRoute : Maybe Route
    , isOnline : Bool
    }


view : Props -> Html Msg
view props =
    Html.header
        [ css
            [ displayFlex
            , alignItems center
            , Style.widthScreen
            , ColorStyle.bgMain
            , height <| px 40
            , Style.borderBottom05
            ]
        ]
        (Html.div
            [ css
                [ displayFlex
                , alignItems center
                , width <| pct 100
                , height <| px 40
                ]
            ]
            [ case props.page of
                Page.Main ->
                    Html.div
                        [ css [ Style.flexCenter, width <| px 32, height <| px 32, marginTop <| px 8 ]
                        , Attributes.dataTest "header-logo"
                        ]
                        [ Html.a [ Attr.href "/", Attr.attribute "aria-label" "Top" ]
                            [ Html.img
                                [ Asset.src Asset.logo
                                , css [ width <| px 28, height <| px 28, marginLeft <| px 4 ]
                                , Attr.alt "logo"
                                ]
                                []
                            ]
                        ]

                _ ->
                    case props.prevRoute of
                        Just r ->
                            Html.div
                                [ css [ Style.flexCenter, padding4 (px 8) (px 8) (px 8) (px 12), cursor pointer ]
                                , Events.onClick <| MoveTo r
                                , Attributes.dataTest "header-back"
                                ]
                                [ Icon.arrowLeft Color.iconColor 18 ]

                        Nothing ->
                            Html.div
                                [ css [ Style.flexCenter, padding4 (px 8) (px 8) (px 8) (px 12), cursor pointer ] ]
                                [ Icon.arrowLeft Color.disabledIconColor 18 ]
            , case props.page of
                Page.Main ->
                    if canEdit props && Title.isEdit props.currentDiagram.title then
                        Html.input
                            [ Attr.id "title"
                            , css
                                [ Style.widthFull
                                , ColorStyle.bgMain
                                , borderStyle none
                                , Font.fontFamily
                                , Text.base
                                , Font.fontBold
                                , padding <| px 8
                                , marginLeft <| px 8
                                , color <| hex <| Color.toString Color.white2
                                , focus
                                    [ outline none
                                    ]
                                ]
                            , Attr.value <| Title.toString props.currentDiagram.title
                            , Events.onInput EditTitle
                            , Events.onBlur EndEditTitle
                            , E.onEnter EndEditTitle
                            , Attr.placeholder "UNTITLED"
                            , Attributes.dataTest "header-input-title"
                            ]
                            []

                    else
                        viewTitle
                            [ css
                                [ cursor pointer
                                , hover []
                                ]
                            , Events.onClick StartEditTitle
                            , Attributes.dataTest "header-title"
                            ]
                            [ Html.text <| Title.toString props.currentDiagram.title
                            , Html.div
                                [ css [ marginLeft <| px 8 ] ]
                                [ if canEdit props && Text.isChanged props.currentText then
                                    Icon.circle Color.white 10

                                  else
                                    Empty.view
                                ]
                            ]

                Page.New ->
                    viewTitle [ Attributes.dataTest "header-title" ] [ Html.text "New Diagram" ]

                Page.Help ->
                    viewTitle [ Attributes.dataTest "header-title" ] [ Html.text "Help" ]

                Page.List ->
                    viewTitle [ Attributes.dataTest "header-title" ] [ Html.text "All Diagrams" ]

                Page.Settings ->
                    viewTitle [ Attributes.dataTest "header-title" ] [ Html.text <| DiagramType.toLongString props.currentDiagram.diagram ++ " Settings" ]

                _ ->
                    Empty.view
            ]
            :: (case props.route of
                    Route.New ->
                        [ Lazy.lazy viewHelpButton props.lang, Lazy.lazy2 viewSignInButton props.menu props.session ]

                    Route.DiagramList ->
                        [ Lazy.lazy viewHelpButton props.lang, Lazy.lazy2 viewSignInButton props.menu props.session ]

                    Route.Settings _ ->
                        [ Lazy.lazy viewHelpButton props.lang, Lazy.lazy2 viewSignInButton props.menu props.session ]

                    _ ->
                        [ Lazy.lazy3 viewLocationButton props.lang props.session props.currentDiagram.location
                        , Lazy.lazy3 viewChangePublicStateButton props.lang props.currentDiagram.isPublic (canChangePublicState props)
                        , Lazy.lazy viewHelpButton props.lang
                        , Lazy.lazy2 viewShareButton props.lang <| canShare props
                        , Lazy.lazy2 viewSignInButton props.menu props.session
                        ]
               )
        )


canChangePublicState : Props -> Bool
canChangePublicState props =
    case ( props.currentDiagram.id, props.currentDiagram.isRemote ) of
        ( Just _, True ) ->
            canEdit props && props.isOnline

        _ ->
            False


canEdit : Props -> Bool
canEdit props =
    case props.route of
        ViewFile _ _ ->
            False

        _ ->
            True


canShare : Props -> Bool
canShare props =
    Session.isSignedIn props.session && isRemoteDiagram props && canEdit props && props.isOnline


isRemoteDiagram : Props -> Bool
isRemoteDiagram props =
    props.currentDiagram.location
        |> Maybe.map DiagramLocation.isRemote
        |> Maybe.withDefault False


viewChangePublicStateButton : Lang -> Bool -> Bool -> Html Msg
viewChangePublicStateButton lang isPublic_ canChangePublicState_ =
    if canChangePublicState_ then
        Html.div
            [ css [ Style.button ], Events.onClick <| ChangePublicStatus (not isPublic_) ]
            [ if isPublic_ then
                Icon.lockOpen Color.iconColor 14

              else
                Icon.lock Color.iconColor 14
            , Tooltip.view <|
                if isPublic_ then
                    Message.toolTipPublic lang

                else
                    Message.toolTipPrivate lang
            ]

    else
        Html.div [ css [ Style.button ] ]
            [ Icon.lock Color.disabledIconColor 14
            , Tooltip.view <| Message.toolTipPrivate lang
            ]


viewHelpButton : Lang -> Html Msg
viewHelpButton lang =
    Html.a
        [ Attr.attribute "aria-label" "Help"
        , css [ displayFlex ]
        , Attr.href <| Route.toString Route.Help
        , Attributes.dataTest "header-help"
        ]
        [ Html.div [ css [ Style.button ] ]
            [ Icon.helpOutline 16
            , Tooltip.view <| Message.toolTipHelp lang
            ]
        ]


viewLocationButton : Lang -> Session -> Maybe DiagramLocation -> Html Msg
viewLocationButton lang session location =
    case ( session, location ) of
        ( Session.SignedIn _, Just DiagramLocation.Remote ) ->
            Html.div
                [ css [ Style.button ] ]
                [ Icon.cloudOn Color.iconColor 14
                , Tooltip.view <| Message.toolTipRemote lang
                ]

        ( Session.SignedIn _, Just DiagramLocation.Gist ) ->
            Html.div
                [ css [ Style.button ] ]
                [ Icon.github Color.iconColor 14
                , Tooltip.view Message.toolTipGist
                ]

        _ ->
            Html.div
                [ css [ Style.button ] ]
                [ Icon.cloudOff Color.iconColor 14
                , Tooltip.view <| Message.toolTipLocal lang
                ]


viewShareButton : Lang -> Bool -> Html Msg
viewShareButton lang canShare_ =
    if canShare_ then
        Html.a
            [ css [ displayFlex ]
            , Attr.href <| Route.toString Route.Share
            , Attr.attribute "aria-label" "Share"
            , Attributes.dataTest "header-share"
            ]
            [ Html.div [ css [ Style.button ] ]
                [ Icon.people Color.iconColor 20
                , Tooltip.view <| Message.toolTipShare lang
                ]
            ]

    else
        Html.div
            [ css [ Style.button ]
            , Attributes.dataTest "header-share"
            ]
            [ Icon.people Color.disabledIconColor 20
            , Tooltip.view <| Message.toolTipShare lang
            ]


viewSignInButton : Maybe Menu -> Session -> Html Msg
viewSignInButton menu session =
    if Session.isSignedIn session then
        let
            user : Maybe Session.User
            user =
                Session.getUser session
        in
        Html.div
            [ css
                [ Breakpoint.style [ width <| px 32 ]
                    [ Breakpoint.small
                        [ Style.button
                        , width <| px 48
                        , height <| px 50
                        ]
                    ]
                ]
            , Events.stopPropagationOn "click" (D.succeed ( OpenMenu HeaderMenu, True ))
            , Attributes.dataTest "header-signin"
            ]
            [ Html.div
                [ css [ Text.sm, marginRight <| px 4 ]
                ]
                [ Html.img
                    [ Avatar.src <| Avatar (Maybe.map .email user) (Maybe.map .photoURL user)
                    , css
                        [ Breakpoint.style
                            [ width <| rem 1.25
                            , Style.heightFull
                            , property "object-fit" "cover"
                            , Style.roundedFull
                            , Style.mtXs
                            , position relative
                            ]
                            [ Breakpoint.large [ width <| rem 1.75, height <| rem 1.75 ] ]
                        ]
                    , Attr.alt "avatar"
                    ]
                    []
                , case menu of
                    Just HeaderMenu ->
                        let
                            user_ : Maybe Session.User
                            user_ =
                                Maybe.andThen
                                    (\u ->
                                        if not <| String.isEmpty u.email then
                                            Just u

                                        else
                                            Nothing
                                    )
                                    user
                        in
                        Menu.menu
                            { top = Just 40
                            , left = Nothing
                            , bottom = Nothing
                            , right = Just 0
                            }
                            (case user_ of
                                Just u ->
                                    [ Menu.MenuItem
                                        { e = NoOp
                                        , title = u.email
                                        }
                                    , Menu.MenuItem
                                        { e = SignOut
                                        , title = "SIGN OUT"
                                        }
                                    ]

                                Nothing ->
                                    [ Menu.MenuItem
                                        { e = SignOut
                                        , title = "SIGN OUT"
                                        }
                                    ]
                            )

                    _ ->
                        Empty.view
                ]
            ]

    else
        Html.div
            [ css [ Style.button, width <| px 96, height <| px 50 ]
            , Events.stopPropagationOn "click" (D.succeed ( OpenMenu LoginMenu, True ))
            , Attributes.dataTest "header-signin"
            ]
            [ Html.div [ css [ Text.base, Font.fontBold ] ]
                [ Html.text "SIGN IN" ]
            , case menu of
                Just LoginMenu ->
                    Menu.menu
                        { top = Just 30
                        , left = Nothing
                        , bottom = Nothing
                        , right = Just 5
                        }
                        [ Menu.MenuItem
                            { e = SignIn Google
                            , title = LoginProvider.toString Google
                            }
                        , Menu.MenuItem
                            { e = SignIn <| Github Nothing
                            , title = LoginProvider.toString <| Github Nothing
                            }
                        ]

                _ ->
                    Empty.view
            ]


viewTitle : List (Html.Attribute msg) -> List (Html msg) -> Html msg
viewTitle attrs children =
    Html.div
        (css
            [ Style.widthFull
            , displayFlex
            , Text.base
            , Font.fontBold
            , overflow hidden
            , alignItems center
            , justifyContent flexStart
            , whiteSpace noWrap
            , ColorStyle.textColor
            , textOverflow ellipsis
            , textAlign left
            , padding <| px 8
            , marginLeft <| px 8
            ]
            :: attrs
        )
        children
