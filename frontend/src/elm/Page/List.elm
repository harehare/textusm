port module Page.List exposing
    ( Model
    , Msg(..)
    , diagramList
    , init
    , load
    , update
    , view
    )

import Api.Request as Request
import Api.RequestError exposing (RequestError)
import Attributes
import Bool.Extra as BoolEx
import Css
    exposing
        ( absolute
        , after
        , alignItems
        , auto
        , backgroundColor
        , backgroundImage
        , backgroundRepeat
        , backgroundSize
        , block
        , border3
        , borderRadius4
        , borderStyle
        , borderTop3
        , bottom
        , calc
        , center
        , color
        , cover
        , cursor
        , display
        , displayFlex
        , ellipsis
        , end
        , focus
        , height
        , hex
        , hidden
        , hover
        , justifyContent
        , left
        , lineHeight
        , marginLeft
        , minus
        , noRepeat
        , noWrap
        , none
        , outline
        , overflow
        , overflowY
        , padding
        , padding4
        , paddingBottom
        , paddingLeft
        , pointer
        , position
        , property
        , px
        , relative
        , rgba
        , right
        , scale
        , scroll
        , solid
        , spaceBetween
        , textAlign
        , textOverflow
        , top
        , transforms
        , url
        , vh
        , whiteSpace
        , zero
        )
import Css.Global exposing (descendants, typeSelector)
import Css.Transitions as Transitions
import Dialog.Confirm as ConfirmDialog
import File exposing (File)
import File.Download as Download
import File.Select as Select
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick, onInput, stopPropagationOn)
import Html.Styled.Lazy as Lazy
import Http
import Json.Decode as D
import Json.Encode as E
import List.Extra exposing (updateIf)
import Message exposing (Lang)
import Models.Color as Color
import Models.Diagram.Id as DiagramId
import Models.Diagram.Item as DiagramItem exposing (DiagramItem)
import Models.Diagram.Location as DiagramLocation
import Models.Dialog as Dialog
import Models.Session as Session exposing (Session)
import Models.Title as Title
import Monocle.Lens exposing (Lens)
import Ordering exposing (Ordering)
import Page.List.DiagramList as DiagramList exposing (DiagramList)
import RemoteData exposing (RemoteData(..))
import Return exposing (Return)
import Simple.Fuzzy as Fuzzy
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
import Style.Font as FontStyle
import Style.Style as Style
import Style.Text as TextStyle
import Task
import Time exposing (Zone)
import Utils.Date as DateUtils
import Utils.Utils as Utils
import Views.Empty as Empty
import Views.Icon as Icon
import Views.Progress as Progress


type Msg
    = SearchInput String
    | Select DiagramItem
    | Bookmark DiagramItem
    | CloseDialog
    | Copy DiagramItem
    | Reload
    | Remove DiagramItem
    | RemoveRemote D.Value
    | Removed (Result RequestError String)
    | Bookmarked (Result RequestError ())
    | GotTimeZone Zone
    | GetDiagrams
    | GotLocalDiagramsJson D.Value
    | GotDiagrams (Result RequestError (List DiagramItem))
    | GetPublicDiagrams Int
    | GotPublicDiagrams (Result RequestError (List DiagramItem))
    | GetBookmarkDiagrams Int
    | GotBookmarkDiagrams (Result RequestError (List DiagramItem))
    | GetGistDiagrams Int
    | GotGistDiagrams (Result RequestError (List DiagramItem))
    | LoadNextPage DiagramList Int
    | Export
    | Import
    | ImportFile File
    | ImportComplete String
    | ShowConfirmDialog DiagramItem


type alias Model =
    { searchQuery : Maybe String
    , timeZone : Zone
    , diagramList : DiagramList
    , session : Session
    , apiRoot : String
    , lang : Lang
    , confirmDialog : Dialog.ConfirmDialog Msg
    , isOnline : Bool
    }


diagramOrder : Ordering DiagramItem
diagramOrder =
    Ordering.byField (\i -> i.updatedAt |> Time.posixToMillis)
        |> Ordering.breakTiesWith (Ordering.byField (\i -> i.title |> Title.toString))
        |> Ordering.breakTiesWith (Ordering.byField (\i -> i.createdAt |> Time.posixToMillis))
        |> Ordering.reverse


diagramList : Lens Model DiagramList
diagramList =
    Lens .diagramList (\b a -> { a | diagramList = b })


pageSize : Int
pageSize =
    30


pageOffsetAndLimit : Int -> ( Int, Int )
pageOffsetAndLimit pageNo =
    ( pageSize * (pageNo - 1), pageSize * pageNo )


port getDiagrams : () -> Cmd msg


port removeDiagrams : E.Value -> Cmd msg


port importDiagram : E.Value -> Cmd msg


init : Session -> Lang -> String -> Bool -> Return Msg Model
init session lang apiRoot isOnline =
    Return.return
        { searchQuery = Nothing
        , timeZone = Time.utc
        , diagramList = DiagramList.notAsked
        , session = session
        , apiRoot = apiRoot
        , lang = lang
        , confirmDialog = Dialog.Hide
        , isOnline = isOnline
        }
        (Task.perform GotTimeZone Time.here)


load : { session : Session, isOnline : Bool } -> Return.ReturnF Msg Model
load { session, isOnline } =
    Return.andThen <|
        \m ->
            Return.singleton { m | session = session, isOnline = isOnline }
                |> Return.command (getDiagrams ())


showDialog : Dialog.ConfirmDialog Msg -> Maybe (Html Msg)
showDialog d =
    case d of
        Dialog.Hide ->
            Nothing

        Dialog.Show { title, message, ok, cancel } ->
            Just <|
                ConfirmDialog.view
                    { title = title
                    , message = message
                    , okButton = { text = "Ok", onClick = ok }
                    , cancelButton = { text = "Cancel", onClick = cancel }
                    }


closeDialog : Return.ReturnF Msg Model
closeDialog =
    Return.map <| \m -> { m | confirmDialog = Dialog.Hide }


itemStyle : Css.Style
itemStyle =
    Css.batch
        [ displayFlex
        , alignItems center
        , cursor pointer
        , TextStyle.sm
        , ColorStyle.textLight
        , height <| px 40
        , lineHeight <| px 30
        , padding4 (px 0) (px 16) (px 2) (px 16)
        , descendants
            [ typeSelector "div"
                [ Style.widthFull
                , overflow hidden
                , whiteSpace noWrap
                , textOverflow ellipsis
                ]
            ]
        , hover [ ColorStyle.textAccent ]
        ]


selectedItemStyle : Css.Style
selectedItemStyle =
    Css.batch
        [ ColorStyle.bgDefault
        , itemStyle
        ]


publicMenu : Session -> DiagramList -> Bool -> Maybe (Html Msg)
publicMenu session list isOnline =
    if Session.isSignedIn session && isOnline then
        Just <|
            Html.div
                [ if DiagramList.isPublicList list then
                    Attr.css [ selectedItemStyle ]

                  else
                    Attr.css [ itemStyle ]
                , onClick <| GetPublicDiagrams 1
                ]
                [ Icon.globe Color.iconColor 16, Html.div [ Attr.css [ Style.paddingSm ] ] [ Html.text "Public" ] ]

    else
        Nothing


bookmarkMenu : Session -> DiagramList -> Bool -> Maybe (Html Msg)
bookmarkMenu session list isOnline =
    if Session.isSignedIn session && isOnline then
        Just <|
            Html.div
                [ if DiagramList.isBookMarkList list then
                    Attr.css [ selectedItemStyle ]

                  else
                    Attr.css [ itemStyle ]
                , onClick <| GetBookmarkDiagrams 1
                ]
                [ Icon.bookmark Color.iconColor 14, Html.div [ Attr.css [ Style.paddingSm ] ] [ Html.text "Bookmarks" ] ]

    else
        Nothing


githubMenu : Session -> DiagramList -> Bool -> Maybe (Html Msg)
githubMenu session list isOnline =
    if Session.isGithubUser session && isOnline then
        Just <|
            Html.div
                [ if DiagramList.isGistList list then
                    Attr.css [ selectedItemStyle ]

                  else
                    Attr.css [ itemStyle ]
                , onClick <| GetGistDiagrams 1
                ]
                [ Icon.github Color.iconColor 14
                , Html.div [ Attr.css [ Style.paddingSm ] ] [ Html.text "Gist" ]
                ]

    else
        Nothing


tabs : Session -> DiagramList -> Bool -> Html Msg
tabs session list isOnline =
    Html.div
        [ Attr.css
            [ Breakpoint.style [ display none ]
                [ Breakpoint.large
                    [ TextStyle.base
                    , Css.displayFlex
                    , ColorStyle.textDark
                    , ColorStyle.bgMain
                    , overflowY scroll
                    ]
                ]
            ]
        ]
        (Html.div
            [ if DiagramList.isAllList list then
                Attr.css [ selectedItemStyle ]

              else
                Attr.css [ itemStyle ]
            , onClick GetDiagrams
            ]
            [ Html.text "All" ]
            :: ([ publicMenu session list isOnline
                , bookmarkMenu session list isOnline
                , githubMenu session list isOnline
                ]
                    |> List.filterMap identity
               )
        )


mainView : List (Html msg) -> Html msg
mainView children =
    Html.div
        [ Attr.css
            [ Breakpoint.style
                [ Style.widthFull
                , height <| calc (vh 100) minus (px 128)
                ]
                [ Breakpoint.large
                    [ displayFlex
                    , ColorStyle.bgDefault
                    , Css.flexDirection Css.column
                    , Style.widthScreen
                    , height <| calc (vh 100) minus (px 40)
                    , position relative
                    ]
                ]
            ]
        , Attributes.dataTest "diagram-list"
        ]
        children


view : Model -> Html Msg
view model =
    case model.diagramList of
        DiagramList.PublicList (Success diagrams) pageNo hasMorePage ->
            mainView
                [ Lazy.lazy3 tabs
                    model.session
                    model.diagramList
                    model.isOnline
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagramList = DiagramList.publicList { list = Success diagrams, pageNo = pageNo, hasMorePage = hasMorePage }
                    , diagrams = diagrams
                    , confirmDialog = model.confirmDialog
                    }
                ]

        DiagramList.BookmarkList (Success diagrams) pageNo hasMorePage ->
            mainView
                [ Lazy.lazy3 tabs
                    model.session
                    model.diagramList
                    model.isOnline
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagramList = DiagramList.bookmarkList { list = Success diagrams, pageNo = pageNo, hasMorePage = hasMorePage }
                    , diagrams = diagrams
                    , confirmDialog = model.confirmDialog
                    }
                ]

        DiagramList.GistList (Success diagrams) pageNo hasMorePage ->
            mainView
                [ Lazy.lazy3 tabs
                    model.session
                    model.diagramList
                    model.isOnline
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagramList = DiagramList.gistList { list = Success diagrams, pageNo = pageNo, hasMorePage = hasMorePage }
                    , diagrams = diagrams
                    , confirmDialog = model.confirmDialog
                    }
                ]

        DiagramList.AllList (Success diagrams) pageNo hasMorePage ->
            mainView
                [ Lazy.lazy3 tabs
                    model.session
                    model.diagramList
                    model.isOnline
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagramList = DiagramList.allList { list = Success diagrams, pageNo = pageNo, hasMorePage = hasMorePage }
                    , diagrams = diagrams
                    , confirmDialog = model.confirmDialog
                    }
                ]

        DiagramList.AllList (Failure e) _ _ ->
            errorView e

        DiagramList.PublicList (Failure e) _ _ ->
            errorView e

        DiagramList.GistList (Failure e) _ _ ->
            errorView e

        DiagramList.BookmarkList (Failure e) _ _ ->
            errorView e

        _ ->
            mainView
                [ Lazy.lazy3 tabs
                    model.session
                    model.diagramList
                    model.isOnline
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = 1
                    , hasMorePage = False
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagramList = DiagramList.allList { list = Success [], pageNo = 1, hasMorePage = False }
                    , diagrams = []
                    , confirmDialog = model.confirmDialog
                    }
                , Progress.view
                ]


diagramListView :
    { timeZone : Zone
    , pageNo : Int
    , hasMorePage : Bool
    , query : Maybe String
    , lang : Lang
    , diagramList : DiagramList
    , diagrams : List DiagramItem
    , confirmDialog : Dialog.ConfirmDialog Msg
    }
    -> Html Msg
diagramListView props =
    Html.div
        [ Attr.css [ Style.widthFull ] ]
        [ Html.div
            [ Attr.css
                [ displayFlex
                , alignItems center
                , justifyContent end
                , Style.paddingSm
                , color <| hex <| Color.toString Color.white
                ]
            ]
            [ Html.div [ Attr.css [ displayFlex, alignItems center, Style.widthFull, position relative ] ]
                [ Html.div
                    [ Attr.css [ position absolute, left <| px 3, top <| px 5 ]
                    ]
                    [ Icon.search (Color.toString Color.labelDefalut) 24 ]
                , Html.input
                    [ Attr.placeholder "Search"
                    , Attr.css
                        [ Style.widthFull
                        , TextStyle.sm
                        , borderStyle none
                        , Style.paddingSm
                        , Style.roundedSm
                        , paddingLeft <| px 32
                        , color <| hex "#000000"
                        , focus
                            [ outline none
                            ]
                        ]
                    , onInput SearchInput
                    ]
                    []
                ]
            , Html.div
                [ Attr.css [ Style.button, marginLeft <| px 8 ]
                , onClick Export
                ]
                [ Icon.cloudDownload Color.white 24
                , Html.span
                    [ Attr.class "bottom-tooltip"
                    ]
                    [ Html.span [ Attr.class "text" ]
                        [ Html.text <| Message.toolTipExport props.lang ]
                    ]
                ]
            , Html.div
                [ Attr.css [ Style.button ]
                , onClick Import
                ]
                [ Icon.cloudUpload Color.white 24
                , Html.span [ Attr.class "bottom-tooltip" ]
                    [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipImport props.lang ] ]
                ]
            ]
        , Html.div [ Attr.css [ overflowY auto, height <| calc (vh 100) minus (px 148) ] ]
            [ Html.div
                [ Attr.css
                    [ Breakpoint.style
                        [ Style.full
                        , ColorStyle.bgDefault
                        , overflowY scroll
                        , padding <| px 16
                        , property "display" "grid"
                        , property "grid-column-gap" "16px"
                        , property "grid-row-gap" "16px"
                        , property "grid-template-columns" "repeat(auto-fit, 47%)"
                        , property "grid-auto-rows" "200px"
                        , property "will-change" "transform"
                        , Style.paddingSm
                        , Style.mbSm
                        , borderTop3 (px 1) solid (hex "#323B46")
                        ]
                        [ Breakpoint.small
                            [ property "grid-template-columns" "repeat(auto-fit, 240px)"
                            , property "grid-auto-rows" "200px"
                            ]
                        ]
                    ]
                ]
                (props.diagrams
                    |> (case props.query of
                            Just query ->
                                List.filter (\d -> Fuzzy.match query (Title.toString d.title))

                            Nothing ->
                                identity
                       )
                    |> List.map
                        (\d -> Lazy.lazy2 diagramView props.timeZone d)
                )
            , hasMorePageButton props.diagramList props.pageNo props.hasMorePage |> Maybe.withDefault Empty.view
            ]
        , showDialog props.confirmDialog |> Maybe.withDefault Empty.view
        ]


hasMorePageButton : DiagramList -> Int -> Bool -> Maybe (Html Msg)
hasMorePageButton list pageNo hasMorePage =
    if hasMorePage then
        Just <|
            Html.div [ Attr.css [ Style.widthFull, Style.flexCenter ] ]
                [ Html.div
                    [ Attr.css [ Style.button, ColorStyle.bgActivity, textAlign center, Style.mSm ]
                    , onClick <| LoadNextPage list <| pageNo + 1
                    ]
                    [ Html.text "Load more" ]
                ]

    else
        Nothing


cloudIconView : List (Html msg) -> Html msg
cloudIconView children =
    Html.div [ Attr.css [ display block, position absolute, top <| px 5, right <| px 32 ] ] children


publicIconView : List (Html msg) -> Html msg
publicIconView children =
    Html.div [ Attr.css [ display block, position absolute, top <| px 5, right <| px 8 ] ] children


bookmarkIconView : DiagramItem -> List (Html Msg) -> Html Msg
bookmarkIconView diagram children =
    Html.div [ Attr.css [ display block, position absolute, bottom <| px 40, right <| px 8 ], stopPropagationOn "click" (D.succeed ( Bookmark diagram, True )) ] children


diagramView : Zone -> DiagramItem -> Html Msg
diagramView timezone diagram =
    Html.div
        [ Attr.css
            [ displayFlex
            , alignItems end
            , justifyContent end
            , backgroundSize cover
            , cursor pointer
            , Style.shadowSm
            , Style.roundedSm
            , Transitions.transition [ Transitions.boxShadow3 100 100 Transitions.easeInOut ]
            , property "will-change" "box-shadow"
            , height <| px 200
            , backgroundRepeat noRepeat
            , position relative
            , backgroundImage <| url (diagram.thumbnail |> Maybe.withDefault "")
            , border3 (px 3) solid ColorStyle.lightBackgroundColor
            , after
                [ Breakpoint.style
                    [ Style.emptyContent
                    , position absolute
                    , top zero
                    , left zero
                    , Style.widthFull
                    , height <| px 120
                    , Transitions.transition [ Transitions.background3 100 100 Transitions.ease ]
                    ]
                    [ Breakpoint.large
                        [ height <| px 120
                        ]
                    ]
                ]
            , hover [ after [ backgroundColor <| rgba 0 0 0 0.2 ] ]
            ]
        , stopPropagationOn "click" (D.succeed ( Select diagram, True ))
        , Attributes.dataTest "diagram-list-item"
        ]
        ([ Html.div
            [ Attr.css
                [ TextStyle.sm
                , Style.widthFull
                , textOverflow ellipsis
                , whiteSpace noWrap
                , overflow hidden
                , ColorStyle.bgLight
                , height <| px 64
                , padding <| px 8
                , borderRadius4 zero zero (px 2) (px 2)
                ]
            ]
            [ Html.div
                [ Attr.css [ overflow hidden, textOverflow ellipsis, TextStyle.base, FontStyle.fontSemiBold ] ]
                [ Html.text (Title.toString diagram.title) ]
            , Html.div
                [ Attr.css [ displayFlex, alignItems center, justifyContent spaceBetween ] ]
                [ Html.div [ Attr.css [ TextStyle.xs, display block, ColorStyle.textDark ] ] [ Html.text (DateUtils.millisToString timezone diagram.updatedAt) ] ]
            ]
         , case diagram.location of
            Just DiagramLocation.Gist ->
                cloudIconView [ Icon.github Color.gray 14 ]

            Just DiagramLocation.Remote ->
                cloudIconView [ Icon.cloudOn Color.gray 14 ]

            _ ->
                cloudIconView [ Icon.cloudOff Color.gray 14 ]
         , if diagram.isPublic then
            publicIconView [ Icon.lockOpen Color.gray 14 ]

           else
            publicIconView [ Icon.lock Color.gray 14 ]
         , copyButtonView diagram
         ]
            ++ ([ bookmarkButtonView diagram
                , deleteButtonView diagram
                ]
                    |> List.filterMap identity
               )
        )


bookmarkButtonView : DiagramItem -> Maybe (Html Msg)
bookmarkButtonView diagram =
    case ( diagram.isBookmark, diagram.location |> Maybe.map DiagramLocation.isRemote |> Maybe.withDefault False ) of
        ( True, True ) ->
            Just <| bookmarkIconView diagram [ Icon.bookmark Color.background2Defalut 16 ]

        ( False, True ) ->
            Just <| bookmarkIconView diagram [ Icon.unbookmark Color.background2Defalut 16 ]

        _ ->
            Nothing


deleteButtonView : DiagramItem -> Maybe (Html Msg)
deleteButtonView diagram =
    if diagram.isPublic then
        Nothing

    else
        Just <|
            Html.div
                [ Attr.css
                    [ bottom <| px -4
                    , right <| px -1
                    , Style.button
                    , position absolute
                    , hover [ transforms [ scale 1.1 ] ]
                    ]
                , stopPropagationOn "click" (D.succeed ( ShowConfirmDialog diagram, True ))
                ]
                [ Icon.clear (Color.toString Color.gray) 18 ]


copyButtonView : DiagramItem -> Html Msg
copyButtonView diagram =
    Html.div
        [ Attr.css
            [ bottom <| px -2
            , right <| px 32
            , Style.button
            , position absolute
            , hover [ transforms [ scale 1.1 ] ]
            ]
        , stopPropagationOn "click" (D.succeed ( Copy diagram, True ))
        ]
        [ Icon.copy Color.gray 14 ]


errorView : Http.Error -> Html Msg
errorView e =
    mainView
        [ Html.div
            [ Attr.css
                [ Style.flexCenter
                , Style.heightFull
                , TextStyle.xl2
                , paddingBottom <| px 32
                , color <| hex <| Color.toString Color.labelDefalut
                ]
            ]
            [ Html.div [ Attr.css [ Style.mbSm ] ]
                [ Html.text ("Failed " ++ Utils.httpErrorToString e)
                ]
            ]
        ]


reload : Return.ReturnF Msg Model
reload =
    Return.andThen <| \m -> Return.return { m | diagramList = DiagramList.notAsked } (getDiagrams ())


fetchAllItems : Session -> Int -> Task.Task RequestError (List DiagramItem)
fetchAllItems session pageNo =
    Request.allItems (Session.getIdToken session) (pageOffsetAndLimit pageNo)
        |> Task.andThen
            (\items ->
                case items of
                    Just items_ ->
                        fetchAllItems session (pageNo + 1)
                            |> Task.map (\items__ -> items_ ++ items__)

                    Nothing ->
                        Task.succeed []
            )


update : Model -> Msg -> Return.ReturnF Msg Model
update model message =
    case message of
        GotTimeZone zone ->
            Return.map <| \m -> { m | timeZone = zone }

        SearchInput input ->
            Return.map <| \m -> { m | searchQuery = BoolEx.toMaybe input (not <| String.isEmpty input) }

        LoadNextPage (DiagramList.AllList remoteData _ hasMorePage) pageNo ->
            Return.map (\m -> { m | diagramList = DiagramList.allList { list = remoteData, pageNo = pageNo, hasMorePage = hasMorePage } }) >> Return.command (getDiagrams ())

        LoadNextPage (DiagramList.PublicList _ _ hasMorePage) pageNo ->
            let
                remoteTask : Task.Task RequestError (List DiagramItem)
                remoteTask =
                    Request.items (Session.getIdToken model.session) (pageOffsetAndLimit pageNo) { isPublic = True, isBookmark = False }
                        |> Task.map (\i -> List.filterMap identity i)
            in
            Return.map (\m -> { m | diagramList = DiagramList.publicList { list = Loading, pageNo = pageNo, hasMorePage = hasMorePage } })
                >> Return.command (Task.attempt GotPublicDiagrams remoteTask)

        LoadNextPage (DiagramList.BookmarkList _ _ hasMorePage) pageNo ->
            let
                remoteTask : Task.Task RequestError (List DiagramItem)
                remoteTask =
                    Request.items (Session.getIdToken model.session) (pageOffsetAndLimit pageNo) { isPublic = False, isBookmark = True }
                        |> Task.map (\i -> List.filterMap identity i)
            in
            Return.map (\m -> { m | diagramList = DiagramList.bookmarkList { list = Loading, pageNo = pageNo, hasMorePage = hasMorePage } })
                >> Return.command (Task.attempt GotBookmarkDiagrams remoteTask)

        LoadNextPage (DiagramList.GistList _ _ hasMorePage) pageNo ->
            Return.map (\m -> { m | diagramList = DiagramList.gistList { list = Loading, pageNo = pageNo, hasMorePage = hasMorePage } })
                >> Return.command
                    (Request.gistItems (Session.getIdToken model.session) (pageOffsetAndLimit pageNo)
                        |> Task.map (\i -> List.filterMap identity i)
                        |> Task.attempt GotGistDiagrams
                    )

        GetPublicDiagrams pageNo ->
            Return.map (\m -> { m | diagramList = DiagramList.publicList { list = Loading, pageNo = pageNo, hasMorePage = DiagramList.hasMorePageInPublicList model.diagramList } })
                >> Return.command
                    (Request.items (Session.getIdToken model.session) (pageOffsetAndLimit pageNo) { isPublic = True, isBookmark = False }
                        |> Task.map (\i -> List.filterMap identity i)
                        |> Task.attempt GotPublicDiagrams
                    )

        GotPublicDiagrams (Ok diagrams) ->
            let
                hasMorePage : Bool
                hasMorePage =
                    List.length diagrams >= pageSize

                ( pageNo, allDiagrams ) =
                    case model.diagramList of
                        DiagramList.PublicList (Success currentDiagrams) p _ ->
                            ( p, Success <| List.concat [ currentDiagrams, diagrams ] )

                        DiagramList.PublicList _ p _ ->
                            ( p, Success diagrams )

                        _ ->
                            ( 1, Success diagrams )
            in
            Return.map <| \m -> { m | diagramList = DiagramList.publicList { list = allDiagrams, pageNo = pageNo, hasMorePage = hasMorePage } }

        GotPublicDiagrams (Err _) ->
            Return.zero

        GetBookmarkDiagrams pageNo ->
            Return.map (\m -> { m | diagramList = DiagramList.bookmarkList { list = Loading, pageNo = pageNo, hasMorePage = DiagramList.hasMorePageInBookmarkList model.diagramList } })
                >> Return.command
                    (Request.items (Session.getIdToken model.session) (pageOffsetAndLimit pageNo) { isPublic = False, isBookmark = True }
                        |> Task.map (\i -> List.filterMap identity i)
                        |> Task.attempt GotBookmarkDiagrams
                    )

        GetDiagrams ->
            reload

        GotBookmarkDiagrams (Ok diagrams) ->
            Return.map <| \m -> { m | diagramList = DiagramList.append model.diagramList diagrams }

        GotBookmarkDiagrams (Err _) ->
            Return.zero

        GetGistDiagrams pageNo ->
            let
                remoteTask : Task.Task RequestError (List DiagramItem)
                remoteTask =
                    Request.gistItems (Session.getIdToken model.session) (pageOffsetAndLimit pageNo)
                        |> Task.map (\i -> List.filterMap identity i)
            in
            Return.map (\m -> { m | diagramList = DiagramList.gistList { list = Loading, pageNo = pageNo, hasMorePage = DiagramList.hasMorePageInGistList model.diagramList } })
                >> Return.command (Task.attempt GotGistDiagrams remoteTask)

        GotGistDiagrams (Ok diagrams) ->
            Return.map (\m -> { m | diagramList = DiagramList.append model.diagramList diagrams })

        GotGistDiagrams (Err _) ->
            Return.zero

        GotLocalDiagramsJson json ->
            case model.diagramList of
                DiagramList.AllList Loading _ _ ->
                    Return.zero

                DiagramList.AllList _ pageNo _ ->
                    let
                        localItems : List DiagramItem
                        localItems =
                            Result.withDefault [] <|
                                D.decodeValue (D.list DiagramItem.decoder) json
                    in
                    if Session.isSignedIn model.session && model.isOnline then
                        let
                            remoteItems : Task.Task RequestError (List DiagramItem)
                            remoteItems =
                                Request.allItems (Session.getIdToken model.session) (pageOffsetAndLimit pageNo)
                                    |> Task.map (\i -> i |> Maybe.withDefault [])

                            items : Task.Task RequestError (List DiagramItem)
                            items =
                                remoteItems
                                    |> Task.map
                                        (\item ->
                                            List.concat [ localItems, item ]
                                                |> List.sortWith diagramOrder
                                        )
                        in
                        Return.map (\m -> { m | diagramList = DiagramList.loading m.diagramList })
                            >> Return.command (Task.attempt GotDiagrams items)

                    else
                        Return.map <| \m -> { m | diagramList = DiagramList.allList { list = Success localItems, pageNo = 1, hasMorePage = False } }

                _ ->
                    Return.zero

        GotDiagrams (Err _) ->
            Return.zero

        GotDiagrams (Ok diagrams) ->
            Return.map <| \m -> { m | diagramList = DiagramList.append model.diagramList diagrams }

        Remove diagram ->
            Return.command (removeDiagrams (DiagramItem.encoder diagram))
                >> closeDialog

        RemoveRemote diagramJson ->
            D.decodeValue DiagramItem.decoder diagramJson
                |> Result.toMaybe
                |> Maybe.map
                    (\diagram ->
                        case ( diagram.location, diagram.id ) of
                            ( Just DiagramLocation.Gist, Just diagramId ) ->
                                Session.getAccessToken model.session
                                    |> Maybe.map
                                        (\accessToken ->
                                            Request.deleteGist (Session.getIdToken model.session) accessToken diagramId
                                                |> Task.map identity
                                                |> Task.attempt Removed
                                                |> Return.command
                                        )
                                    |> Maybe.withDefault Return.zero

                            ( _, Just diagramId ) ->
                                Request.delete (Session.getIdToken model.session) diagramId False
                                    |> Task.map identity
                                    |> Task.attempt Removed
                                    |> Return.command

                            _ ->
                                Return.zero
                    )
                |> Maybe.withDefault Return.zero

        Removed (Err _) ->
            Return.zero

        Removed (Ok _) ->
            reload

        Reload ->
            reload

        Bookmark diagram ->
            let
                { list, pageNo, hasMorePage } =
                    DiagramList.unwrap model.diagramList
            in
            Return.map
                (\m ->
                    { m
                        | diagramList =
                            DiagramList.create m.diagramList
                                (RemoteData.withDefault [] list |> updateIf (\item -> item.id == diagram.id) (\item -> { item | isBookmark = not item.isBookmark }))
                                pageNo
                                hasMorePage
                    }
                )
                >> Return.command
                    (Task.attempt Bookmarked
                        (Request.bookmark (Session.getIdToken model.session)
                            (Maybe.map DiagramId.toString diagram.id |> Maybe.withDefault "")
                            (not diagram.isBookmark)
                            |> Task.map (\_ -> ())
                        )
                    )

        Import ->
            Return.command <| Select.file [ "application/json" ] ImportFile

        ImportFile file ->
            Return.command <| Task.perform ImportComplete <| File.toString file

        ImportComplete json ->
            DiagramItem.stringToList json
                |> Result.toMaybe
                |> Maybe.map
                    (\diagrams ->
                        Return.command <| importDiagram <| DiagramItem.listToValue diagrams
                    )
                |> Maybe.withDefault Return.zero

        Export ->
            case model.diagramList of
                DiagramList.AllList (Success diagrams) _ _ ->
                    Return.command <| Download.string "textusm.json" "application/json" <| DiagramItem.listToString diagrams

                _ ->
                    Return.zero

        CloseDialog ->
            closeDialog

        ShowConfirmDialog d ->
            Return.map <|
                \m ->
                    { m
                        | confirmDialog =
                            Dialog.Show
                                { title = "Confirmation"
                                , message = "Are you sure you want to delete " ++ Title.toString d.title ++ " diagram?`"
                                , ok = Remove d
                                , cancel = CloseDialog
                                }
                    }

        Bookmarked (Ok _) ->
            Return.zero

        Bookmarked (Err _) ->
            Return.zero

        -- Processed by parent component
        Select _ ->
            Return.zero

        Copy _ ->
            Return.zero
