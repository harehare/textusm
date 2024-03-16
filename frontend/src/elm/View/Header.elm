module View.Header exposing (Props, docs, view)

import Asset
import Attributes
import Avatar exposing (Avatar(..))
import Css
import Diagram.Types.Item as DiagramItem exposing (DiagramItem)
import Diagram.Types.Location as DiagramLocation
import Diagram.Types.Type as DiagramType exposing (DiagramType)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Events as E
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events
import Html.Styled.Lazy as Lazy
import Json.Decode as D
import Message exposing (Lang)
import Page.Types as Page exposing (Page)
import Route exposing (Route(..))
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
import Style.Font as Font
import Style.Global as GlobalStyle
import Style.Style as Style
import Style.Text as Text
import Types exposing (Menu(..))
import Types.Color as Color
import Types.LoginProvider as LoginProvider exposing (LoginProvider(..))
import Types.Session as Session exposing (Session)
import Types.Text as Text exposing (Text)
import Types.Title as Title
import View.Empty as Empty
import View.Icon as Icon
import View.Menu as Menu
import View.Tooltip as Tooltip


type alias Props msg =
    { session : Session
    , page : Page
    , currentDiagram : DiagramItem
    , menu : Maybe Menu
    , currentText : Text
    , lang : Lang
    , route : Route
    , prevRoute : Maybe Route
    , isOnline : Bool
    , onMoveTo : Route -> msg
    , onStartEditTitle : msg
    , onEditTitle : String -> msg
    , onEndEditTitle : msg
    , onChangePublicStatus : Bool -> msg
    , onOpenMenu : Menu -> msg
    , onCloseMenu : msg
    , onSignIn : LoginProvider -> msg
    , onSignOut : msg
    }


view : Props msg -> Html msg
view props =
    Html.header
        [ css
            [ Css.displayFlex
            , Css.alignItems Css.center
            , Style.widthFull
            , ColorStyle.bgHeaderColor
            , Css.height <| Css.px 40
            ]
        ]
        (Html.div
            [ css
                [ Css.displayFlex
                , Css.width <| Css.pct 100
                , Css.height <| Css.pct 100
                ]
            ]
            [ case props.page of
                Page.Main ->
                    Html.div
                        [ css [ Css.width <| Css.px 32, Css.height <| Css.px 32, Css.marginTop <| Css.px 6 ]
                        , Attributes.dataTest "header-logo"
                        ]
                        [ Html.a [ Attr.href "/", Attr.attribute "aria-label" "Top" ]
                            [ Html.img
                                [ Asset.src Asset.logo
                                , css [ Css.width <| Css.px 28, Css.height <| Css.px 28, Css.marginLeft <| Css.px 4 ]
                                , Attr.alt "logo"
                                ]
                                []
                            ]
                        ]

                _ ->
                    case props.prevRoute of
                        Just r ->
                            Html.div
                                [ css [ Style.flexCenter, Css.padding4 (Css.px 8) (Css.px 8) (Css.px 8) (Css.px 12), Css.cursor Css.pointer ]
                                , Events.onClick <| props.onMoveTo r
                                , Attributes.dataTest "header-back"
                                ]
                                [ Icon.arrowLeft Color.iconColor 16 ]

                        Nothing ->
                            Html.div
                                [ css [ Style.flexCenter, Css.padding4 (Css.px 8) (Css.px 8) (Css.px 8) (Css.px 12), Css.cursor Css.pointer ] ]
                                [ Icon.arrowLeft Color.disabledIconColor 16 ]
            , case props.page of
                Page.Main ->
                    if canEdit props && Title.isEdit props.currentDiagram.title then
                        Html.input
                            [ Attr.id "title"
                            , css
                                [ Style.widthFull
                                , ColorStyle.bgHeaderColor
                                , Css.borderStyle Css.none
                                , Font.fontFamily
                                , Text.base
                                , Font.fontBold
                                , Css.paddingLeft <| Css.px 8
                                , Css.color <| Css.hex <| Color.toString Color.white2
                                , Css.focus
                                    [ Css.outline Css.none
                                    ]
                                ]
                            , Attr.value <| Title.toString props.currentDiagram.title
                            , Events.onInput props.onEditTitle
                            , Events.onBlur props.onEndEditTitle
                            , E.onEnter props.onEndEditTitle
                            , Attr.placeholder "UNTITLED"
                            , Attributes.dataTest "header-input-title"
                            ]
                            []

                    else
                        viewTitle
                            [ css
                                [ Css.cursor Css.pointer
                                , Css.hover []
                                ]
                            , Events.onClick props.onStartEditTitle
                            , Attributes.dataTest "header-title"
                            ]
                            [ Html.text <| Title.toString props.currentDiagram.title
                            , Html.div
                                [ css [ Css.marginLeft <| Css.px 8 ] ]
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
                        [ Lazy.lazy viewHelpButton props.lang
                        , Lazy.lazy2 viewSettingsButton props.lang props.currentDiagram.diagram
                        , Lazy.lazy viewSignInButton { menu = props.menu, session = props.session, onOpenMenu = props.onOpenMenu, onSignIn = props.onSignIn, onSignOut = props.onSignOut, onCloseMenu = props.onCloseMenu }
                        ]

                    Route.DiagramList ->
                        [ Lazy.lazy viewHelpButton props.lang
                        , Lazy.lazy2 viewSettingsButton props.lang props.currentDiagram.diagram
                        , Lazy.lazy viewSignInButton { menu = props.menu, session = props.session, onOpenMenu = props.onOpenMenu, onSignIn = props.onSignIn, onSignOut = props.onSignOut, onCloseMenu = props.onCloseMenu }
                        ]

                    Route.Settings _ ->
                        [ Lazy.lazy viewHelpButton props.lang
                        , Lazy.lazy2 viewSettingsButton props.lang props.currentDiagram.diagram
                        , Lazy.lazy viewSignInButton { menu = props.menu, session = props.session, onOpenMenu = props.onOpenMenu, onSignIn = props.onSignIn, onSignOut = props.onSignOut, onCloseMenu = props.onCloseMenu }
                        ]

                    _ ->
                        [ Lazy.lazy4 viewChangePublicStateButton props.onChangePublicStatus props.lang props.currentDiagram.isPublic (canChangePublicState props)
                        , Lazy.lazy viewHelpButton props.lang
                        , Lazy.lazy2 viewShareButton props.lang <| canShare props
                        , Lazy.lazy2 viewSettingsButton props.lang props.currentDiagram.diagram
                        , Lazy.lazy viewSignInButton { menu = props.menu, session = props.session, onOpenMenu = props.onOpenMenu, onSignIn = props.onSignIn, onSignOut = props.onSignOut, onCloseMenu = props.onCloseMenu }
                        ]
               )
        )


canChangePublicState : Props msg -> Bool
canChangePublicState props =
    props.currentDiagram.id
        |> Maybe.andThen (\_ -> props.currentDiagram.location)
        |> Maybe.map (\loc -> DiagramLocation.isRemote loc && canEdit props && props.isOnline)
        |> Maybe.withDefault False


canEdit : Props msg -> Bool
canEdit props =
    case props.route of
        ViewFile _ _ ->
            False

        _ ->
            True


canShare : Props msg -> Bool
canShare props =
    Session.isSignedIn props.session && isRemoteDiagram props && canEdit props && props.isOnline


isRemoteDiagram : Props msg -> Bool
isRemoteDiagram props =
    props.currentDiagram.location
        |> Maybe.map DiagramLocation.isRemote
        |> Maybe.withDefault False


viewChangePublicStateButton : (Bool -> msg) -> Lang -> Bool -> Bool -> Html msg
viewChangePublicStateButton onChangePublicStatus lang isPublic_ canChangePublicState_ =
    if canChangePublicState_ then
        Html.div
            [ css [ Style.button ], Events.onClick <| onChangePublicStatus (not isPublic_) ]
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


viewHelpButton : Lang -> Html msg
viewHelpButton lang =
    Html.a
        [ Attr.attribute "aria-label" "Help"
        , css [ Css.displayFlex ]
        , Attr.href <| Route.toString Route.Help
        , Attributes.dataTest "header-help"
        ]
        [ Html.div [ css [ Style.button ] ]
            [ Icon.helpOutline 16
            , Tooltip.view <| Message.toolTipHelp lang
            ]
        ]


viewSettingsButton : Lang -> DiagramType -> Html msg
viewSettingsButton lang diagramType =
    Html.a
        [ Attr.attribute "aria-label" "Help"
        , css [ Css.displayFlex ]
        , Attr.href <|
            Route.toString (Route.Settings diagramType)
        , Attr.attribute "aria-label" "Settings"
        , Attributes.dataTest "header-settings"
        ]
        [ Html.div [ css [ Style.button ] ]
            [ Icon.settings Color.iconColor 16
            , Tooltip.view <| Message.toolTipSettings lang
            ]
        ]


viewShareButton : Lang -> Bool -> Html msg
viewShareButton lang canShare_ =
    if canShare_ then
        Html.a
            [ css [ Css.displayFlex ]
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


viewSignInButton : { menu : Maybe Menu, session : Session, onOpenMenu : Menu -> msg, onSignIn : LoginProvider -> msg, onSignOut : msg, onCloseMenu : msg } -> Html msg
viewSignInButton { menu, session, onOpenMenu, onSignIn, onSignOut, onCloseMenu } =
    if Session.isSignedIn session then
        let
            user : Maybe Session.User
            user =
                Session.getUser session
        in
        Html.div
            [ css
                [ Breakpoint.style
                    [ Css.width <| Css.px 32
                    , Css.marginLeft <| Css.px 8
                    , Css.marginRight <| Css.px 8
                    ]
                    [ Breakpoint.small
                        [ Style.button
                        , Css.width <| Css.px 40
                        , Css.height <| Css.px 40
                        ]
                    ]
                ]
            , Events.stopPropagationOn "click" (D.succeed ( onOpenMenu HeaderMenu, True ))
            , Attributes.dataTest "header-signin"
            ]
            [ Html.div
                [ css [ Text.sm, Css.marginRight <| Css.px 4 ]
                ]
                [ Html.img
                    [ Avatar.src <| Avatar (Maybe.map .email user) (Maybe.map .photoURL user)
                    , css
                        [ Breakpoint.style
                            [ Css.width <| Css.rem 1.25
                            , Style.heightFull
                            , Css.property "object-fit" "cover"
                            , Style.roundedFull
                            , Style.mtXs
                            , Css.position Css.relative
                            ]
                            [ Breakpoint.large [ Css.width <| Css.rem 1.5, Css.height <| Css.rem 1.5 ] ]
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
                            { bottom = Nothing
                            , left = Nothing
                            , right = Just 0
                            , top = Just 40
                            }
                            (case user_ of
                                Just u ->
                                    [ Menu.MenuItem
                                        { e = Nothing
                                        , title = u.email
                                        }
                                    , Menu.MenuItem
                                        { e = Just onSignOut
                                        , title = "SIGN OUT"
                                        }
                                    ]

                                Nothing ->
                                    [ Menu.MenuItem
                                        { e = Just onSignOut
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
            [ css [ Style.button, Css.width <| Css.px 96, Css.height <| Css.px 40 ]
            , case menu of
                Just LoginMenu ->
                    Events.stopPropagationOn "click" (D.succeed ( onCloseMenu, True ))

                _ ->
                    Events.stopPropagationOn "click" (D.succeed ( onOpenMenu LoginMenu, True ))
            , Attributes.dataTest "header-signin"
            ]
            [ Html.div
                [ css
                    [ Font.fontBold
                    , Text.xs
                    , Breakpoint.style
                        [ Font.fontBold
                        ]
                        [ Breakpoint.large [ Text.base ] ]
                    ]
                ]
                [ Html.text "SIGN IN" ]
            , case menu of
                Just LoginMenu ->
                    Menu.menu
                        { bottom = Nothing
                        , left = Nothing
                        , right = Just -6
                        , top = Just 40
                        }
                        [ Menu.MenuItem
                            { e = Just <| onSignIn Google
                            , title = LoginProvider.toString Google
                            }
                        , Menu.MenuItem
                            { e = Just <| onSignIn <| Github Nothing
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
            , Css.displayFlex
            , Text.base
            , Font.fontBold
            , Css.overflow Css.hidden
            , Css.alignItems Css.center
            , Css.justifyContent Css.flexStart
            , Css.whiteSpace Css.noWrap
            , ColorStyle.textColor
            , Css.textOverflow Css.ellipsis
            , Css.textAlign Css.left
            , Css.paddingLeft <| Css.px 8
            ]
            :: attrs
        )
        children


docs : Chapter x
docs =
    Chapter.chapter "Header"
        |> Chapter.renderComponent
            (Html.div []
                [ GlobalStyle.style
                , view
                    { session = Session.guest
                    , page = Page.Main
                    , currentDiagram = DiagramItem.empty
                    , menu = Nothing
                    , currentText = Text.empty
                    , lang = Message.En
                    , route = Route.Home
                    , prevRoute = Nothing
                    , isOnline = True
                    , onMoveTo = \_ -> Actions.logAction "onMoveTo"
                    , onStartEditTitle = Actions.logAction "onStartEditTitle"
                    , onEditTitle = \_ -> Actions.logAction "onEditTitle"
                    , onEndEditTitle = Actions.logAction "onEndEditTitle"
                    , onChangePublicStatus = \_ -> Actions.logAction "onChangePublicStatus"
                    , onOpenMenu = \_ -> Actions.logAction "onOpenMenu"
                    , onCloseMenu = Actions.logAction "onCloseMenu"
                    , onSignIn = \_ -> Actions.logAction "onSignIn"
                    , onSignOut = Actions.logAction "onSignOut"
                    }
                ]
                |> Html.toUnstyled
            )
