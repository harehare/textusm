port module Page.List exposing
    ( DiagramList(..)
    , Model
    , Msg(..)
    , init
    , modelOfDiagramList
    , notAsked
    , update
    , view
    )

import Api.Request as Request
import Api.RequestError exposing (RequestError)
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
        , padding2
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
        , width
        , zero
        )
import Css.Global exposing (children, descendants, typeSelector)
import Css.Transitions as Transitions
import Dialog.Confirm as ConfirmDialog
import File exposing (File)
import File.Download as Download
import File.Select as Select
import Graphql.Object.GistItem exposing (diagram)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (class, css, placeholder)
import Html.Styled.Events exposing (onClick, onInput, stopPropagationOn)
import Html.Styled.Lazy as Lazy
import Http
import Json.Decode as D
import Json.Encode as E
import List.Extra exposing (updateIf)
import Message exposing (Lang)
import Models.Color as Color
import Models.DiagramId as DiagramId
import Models.DiagramItem as DiagramItem exposing (DiagramItem)
import Models.DiagramLocation as DiagramLocation
import Models.Dialog as Dialog
import Models.Session as Session exposing (Session)
import Models.Title as Title
import Monocle.Lens exposing (Lens)
import Ordering exposing (Ordering)
import RemoteData exposing (RemoteData(..), WebData)
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


type DiagramList
    = AllList (WebData (List DiagramItem)) Int Bool
    | PublicList (WebData (List DiagramItem)) Int Bool
    | BookmarkList (WebData (List DiagramItem)) Int Bool
    | GistList (WebData (List DiagramItem)) Int Bool


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


createDiagramList : DiagramList -> List DiagramItem -> Int -> Bool -> DiagramList
createDiagramList diagramList data page hasMorePage =
    case diagramList of
        AllList _ _ _ ->
            AllList (Success data) page hasMorePage

        PublicList _ _ _ ->
            PublicList (Success data) page hasMorePage

        BookmarkList _ _ _ ->
            BookmarkList (Success data) page hasMorePage

        GistList _ _ _ ->
            GistList (Success data) page hasMorePage


diagramOrder : Ordering DiagramItem
diagramOrder =
    Ordering.byField (\i -> i.updatedAt |> Time.posixToMillis)
        |> Ordering.breakTiesWith (Ordering.byField (\i -> i.title |> Title.toString))
        |> Ordering.breakTiesWith (Ordering.byField (\i -> i.createdAt |> Time.posixToMillis))
        |> Ordering.reverse


modelOfDiagramList : Lens Model DiagramList
modelOfDiagramList =
    Lens .diagramList (\b a -> { a | diagramList = b })


notAsked : DiagramList
notAsked =
    AllList NotAsked 1 False


isAllList : DiagramList -> Bool
isAllList data =
    case data of
        AllList _ _ _ ->
            True

        _ ->
            False


isBookMarkList : DiagramList -> Bool
isBookMarkList data =
    case data of
        BookmarkList _ _ _ ->
            True

        _ ->
            False


isPublicList : DiagramList -> Bool
isPublicList data =
    case data of
        PublicList _ _ _ ->
            True

        _ ->
            False


isGistList : DiagramList -> Bool
isGistList data =
    case data of
        GistList _ _ _ ->
            True

        _ ->
            False


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
        , diagramList = notAsked
        , session = session
        , apiRoot = apiRoot
        , lang = lang
        , confirmDialog = Dialog.Hide
        , isOnline = isOnline
        }
        (Task.perform GotTimeZone Time.here)
        |> Return.command (getDiagrams ())


showDialog : Dialog.ConfirmDialog Msg -> Html Msg
showDialog d =
    case d of
        Dialog.Hide ->
            Empty.view

        Dialog.Show { title, message, ok, cancel } ->
            ConfirmDialog.view
                { title = title
                , message = message
                , okButton = { text = "Ok", onClick = ok }
                , cancelButton = { text = "Cancel", onClick = cancel }
                }


closeDialog : Model -> Return Msg Model
closeDialog model =
    Return.singleton { model | confirmDialog = Dialog.Hide }


itemStyle : Css.Style
itemStyle =
    Css.batch
        [ displayFlex
        , alignItems center
        , cursor pointer
        , TextStyle.sm
        , ColorStyle.textLight
        , height <| px 32
        , lineHeight <| px 30
        , padding2 (px 8) (px 8)
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


sideMenu : Session -> DiagramList -> Bool -> Html Msg
sideMenu session diagramList isOnline =
    Html.div
        [ css
            [ Breakpoint.style [ display none ]
                [ Breakpoint.large
                    [ TextStyle.base
                    , ColorStyle.textDark
                    , ColorStyle.bgMain
                    , overflowY scroll
                    , display block
                    , width <| px 250
                    , height <| calc (vh 100) minus (px 40)
                    ]
                ]
            ]
        ]
        [ Html.div
            [ if isAllList diagramList then
                css [ selectedItemStyle ]

              else
                css [ itemStyle ]
            , onClick GetDiagrams
            ]
            [ Html.text "All" ]
        , if Session.isSignedIn session && isOnline then
            Html.div
                [ if isPublicList diagramList then
                    css [ selectedItemStyle ]

                  else
                    css [ itemStyle ]
                , onClick <| GetPublicDiagrams 1
                ]
                [ Icon.globe Color.iconColor 16, Html.div [ css [ Style.paddingSm ] ] [ Html.text "Public" ] ]

          else
            Empty.view
        , if Session.isSignedIn session && isOnline then
            Html.div
                [ if isBookMarkList diagramList then
                    css [ selectedItemStyle ]

                  else
                    css [ itemStyle ]
                , onClick <| GetBookmarkDiagrams 1
                ]
                [ Icon.bookmark Color.iconColor 14, Html.div [ css [ Style.paddingSm ] ] [ Html.text "Bookmarks" ] ]

          else
            Empty.view
        , if Session.isGithubUser session && isOnline then
            Html.div
                [ if isGistList diagramList then
                    css [ selectedItemStyle ]

                  else
                    css [ itemStyle ]
                , onClick <| GetGistDiagrams 1
                ]
                [ Icon.github Color.iconColor 14
                , Html.div [ css [ Style.paddingSm ] ] [ Html.text "Gist" ]
                ]

          else
            Empty.view
        ]


mainView : List (Html msg) -> Html msg
mainView children =
    Html.div
        [ css
            [ Breakpoint.style
                [ Style.widthFull
                , height <| calc (vh 100) minus (px 128)
                ]
                [ Breakpoint.large
                    [ displayFlex
                    , ColorStyle.bgDefault
                    , Style.widthScreen
                    , height <| calc (vh 100) minus (px 40)
                    , position relative
                    ]
                ]
            ]
        ]
        children


view : Model -> Html Msg
view model =
    case model.diagramList of
        PublicList (Success diagrams) pageNo hasMorePage ->
            mainView
                [ Lazy.lazy3 sideMenu
                    model.session
                    model.diagramList
                    model.isOnline
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagramList = PublicList (Success diagrams) pageNo hasMorePage
                    , diagrams = diagrams
                    , confirmDialog = model.confirmDialog
                    }
                ]

        BookmarkList (Success diagrams) pageNo hasMorePage ->
            mainView
                [ Lazy.lazy3 sideMenu
                    model.session
                    model.diagramList
                    model.isOnline
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagramList = BookmarkList (Success diagrams) pageNo hasMorePage
                    , diagrams = diagrams
                    , confirmDialog = model.confirmDialog
                    }
                ]

        GistList (Success diagrams) pageNo hasMorePage ->
            mainView
                [ Lazy.lazy3 sideMenu
                    model.session
                    model.diagramList
                    model.isOnline
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagramList = GistList (Success diagrams) pageNo hasMorePage
                    , diagrams = diagrams
                    , confirmDialog = model.confirmDialog
                    }
                ]

        AllList (Success diagrams) pageNo hasMorePage ->
            mainView
                [ Lazy.lazy3 sideMenu
                    model.session
                    model.diagramList
                    model.isOnline
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagramList = AllList (Success diagrams) pageNo hasMorePage
                    , diagrams = diagrams
                    , confirmDialog = model.confirmDialog
                    }
                ]

        AllList (Failure e) _ _ ->
            errorView e

        PublicList (Failure e) _ _ ->
            errorView e

        GistList (Failure e) _ _ ->
            errorView e

        BookmarkList (Failure e) _ _ ->
            errorView e

        _ ->
            mainView
                [ Lazy.lazy3 sideMenu
                    model.session
                    model.diagramList
                    model.isOnline
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = 1
                    , hasMorePage = False
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagramList = AllList (Success []) 1 False
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
        [ css [ Style.widthFull ] ]
        [ Html.div
            [ css
                [ displayFlex
                , alignItems center
                , justifyContent end
                , Style.paddingMd
                , color <| hex <| Color.toString Color.white
                ]
            ]
            [ Html.div [ css [ displayFlex, alignItems center, Style.widthFull, position relative ] ]
                [ Html.div
                    [ css [ position absolute, left <| px 3, top <| px 5 ]
                    ]
                    [ Icon.search (Color.toString Color.labelDefalut) 24 ]
                , Html.input
                    [ placeholder "Search"
                    , css
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
                [ css [ Style.button, marginLeft <| px 8 ]
                , onClick Export
                ]
                [ Icon.cloudDownload Color.white 24, Html.span [ class "bottom-tooltip" ] [ Html.span [ class "text" ] [ Html.text <| Message.toolTipExport props.lang ] ] ]
            , Html.div
                [ css [ Style.button ]
                , onClick Import
                ]
                [ Icon.cloudUpload Color.white 24, Html.span [ class "bottom-tooltip" ] [ Html.span [ class "text" ] [ Html.text <| Message.toolTipImport props.lang ] ] ]
            ]
        , Html.div [ css [ overflowY auto, height <| calc (vh 100) minus (px 148) ] ]
            [ Html.div
                [ css
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
            , if props.hasMorePage then
                Html.div [ css [ Style.widthFull, Style.flexCenter ] ]
                    [ Html.div
                        [ css [ Style.button, ColorStyle.bgActivity, textAlign center, Style.mSm ]
                        , onClick <| LoadNextPage props.diagramList <| props.pageNo + 1
                        ]
                        [ Html.text "Load more" ]
                    ]

              else
                Empty.view
            ]
        , Lazy.lazy showDialog props.confirmDialog
        ]


cloudIconView : List (Html msg) -> Html msg
cloudIconView children =
    Html.div [ css [ display block, position absolute, top <| px 5, right <| px 32 ] ] children


publicIconView : List (Html msg) -> Html msg
publicIconView children =
    Html.div [ css [ display block, position absolute, top <| px 5, right <| px 8 ] ] children


bookmarkIconView : DiagramItem -> List (Html Msg) -> Html Msg
bookmarkIconView diagram children =
    Html.div [ css [ display block, position absolute, bottom <| px 40, right <| px 8 ], stopPropagationOn "click" (D.succeed ( Bookmark diagram, True )) ] children


diagramView : Zone -> DiagramItem -> Html Msg
diagramView timezone diagram =
    Html.div
        [ css
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
                        [ height <| px 150
                        ]
                    ]
                ]
            , hover [ after [ backgroundColor <| rgba 0 0 0 0.2 ] ]
            ]
        , stopPropagationOn "click" (D.succeed ( Select diagram, True ))
        ]
        [ Html.div
            [ css
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
                [ css [ overflow hidden, textOverflow ellipsis, TextStyle.base, FontStyle.fontSemiBold ] ]
                [ Html.text (Title.toString diagram.title) ]
            , Html.div
                [ css [ displayFlex, alignItems center, justifyContent spaceBetween ] ]
                [ Html.div [ css [ TextStyle.xs, display block, ColorStyle.textDark ] ] [ Html.text (DateUtils.millisToString timezone diagram.updatedAt) ] ]
            ]
        , case diagram.location of
            Just DiagramLocation.Gist ->
                cloudIconView [ Icon.github Color.gray 14 ]

            Just DiagramLocation.Remote ->
                cloudIconView [ Icon.cloudOn 14 ]

            _ ->
                cloudIconView [ Icon.cloudOff 14 ]
        , if diagram.isPublic then
            publicIconView [ Icon.lockOpen Color.gray 14 ]

          else
            publicIconView [ Icon.lock Color.gray 14 ]
        , if diagram.isPublic then
            Empty.view

          else
            Html.div
                [ css
                    [ bottom <| px -4
                    , right <| px -1
                    , Style.button
                    , position absolute
                    , hover [ transforms [ scale 1.1 ] ]
                    ]
                , stopPropagationOn "click" (D.succeed ( ShowConfirmDialog diagram, True ))
                ]
                [ Icon.clear "#333" 18 ]
        , case ( diagram.isBookmark, diagram.isRemote ) of
            ( True, True ) ->
                bookmarkIconView diagram [ Icon.bookmark Color.background2Defalut 16 ]

            ( False, True ) ->
                bookmarkIconView diagram [ Icon.unbookmark Color.background2Defalut 16 ]

            _ ->
                Empty.view
        ]


errorView : Http.Error -> Html Msg
errorView e =
    mainView
        [ Html.div
            [ css
                [ Style.flexCenter
                , Style.heightFull
                , TextStyle.xl2
                , paddingBottom <| px 32
                , color <| hex <| Color.toString Color.labelDefalut
                ]
            ]
            [ Html.div [ css [ Style.mbSm ] ]
                [ Html.text ("Failed " ++ Utils.httpErrorToString e)
                ]
            ]
        ]


reload : Return.ReturnF Msg Model
reload =
    Return.andThen <| \m -> Return.return { m | diagramList = notAsked } (getDiagrams ())


update : Msg -> Return.ReturnF Msg Model
update message =
    case message of
        GotTimeZone zone ->
            Return.andThen <| \m -> Return.singleton { m | timeZone = zone }

        SearchInput input ->
            Return.andThen <|
                \m ->
                    Return.singleton
                        { m
                            | searchQuery =
                                if String.isEmpty input then
                                    Nothing

                                else
                                    Just input
                        }

        LoadNextPage (AllList remoteData _ hasMorePage) pageNo ->
            Return.andThen
                (\m ->
                    Return.return { m | diagramList = AllList remoteData pageNo hasMorePage } (getDiagrams ())
                )

        LoadNextPage (PublicList _ _ hasMorePage) pageNo ->
            Return.andThen
                (\m ->
                    let
                        remoteTask : Task.Task RequestError (List DiagramItem)
                        remoteTask =
                            Request.items (Session.getIdToken m.session) (pageOffsetAndLimit pageNo) { isPublic = True, isBookmark = False }
                                |> Task.map (\i -> List.filterMap identity i)
                    in
                    Return.return { m | diagramList = PublicList Loading pageNo hasMorePage } <| Task.attempt GotPublicDiagrams remoteTask
                )

        LoadNextPage (BookmarkList _ _ hasMorePage) pageNo ->
            Return.andThen
                (\m ->
                    let
                        remoteTask : Task.Task RequestError (List DiagramItem)
                        remoteTask =
                            Request.items (Session.getIdToken m.session) (pageOffsetAndLimit pageNo) { isPublic = False, isBookmark = True }
                                |> Task.map (\i -> List.filterMap identity i)
                    in
                    Return.return { m | diagramList = BookmarkList Loading pageNo hasMorePage } <| Task.attempt GotBookmarkDiagrams remoteTask
                )

        LoadNextPage (GistList _ _ hasMorePage) pageNo ->
            Return.andThen
                (\m ->
                    let
                        remoteTask : Task.Task RequestError (List DiagramItem)
                        remoteTask =
                            Request.gistItems (Session.getIdToken m.session) (pageOffsetAndLimit pageNo)
                                |> Task.map (\i -> List.filterMap identity i)
                    in
                    Return.return { m | diagramList = GistList Loading pageNo hasMorePage } <| Task.attempt GotGistDiagrams remoteTask
                )

        GetPublicDiagrams pageNo ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage : Bool
                        hasMorePage =
                            case m.diagramList of
                                PublicList _ _ h ->
                                    h

                                _ ->
                                    False

                        remoteTask : Task.Task RequestError (List DiagramItem)
                        remoteTask =
                            Request.items (Session.getIdToken m.session) (pageOffsetAndLimit pageNo) { isPublic = True, isBookmark = False }
                                |> Task.map (\i -> List.filterMap identity i)
                    in
                    Return.return { m | diagramList = PublicList Loading pageNo hasMorePage } <| Task.attempt GotPublicDiagrams remoteTask
                )

        GotPublicDiagrams (Ok diagrams) ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage : Bool
                        hasMorePage =
                            List.length diagrams >= pageSize

                        ( pageNo, allDiagrams ) =
                            case m.diagramList of
                                PublicList (Success currentDiagrams) p _ ->
                                    ( p, Success <| List.concat [ currentDiagrams, diagrams ] )

                                PublicList _ p _ ->
                                    ( p, Success diagrams )

                                _ ->
                                    ( 1, Success diagrams )
                    in
                    Return.singleton { m | diagramList = PublicList allDiagrams pageNo hasMorePage }
                )

        GotPublicDiagrams (Err _) ->
            Return.zero

        GetBookmarkDiagrams pageNo ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage : Bool
                        hasMorePage =
                            case m.diagramList of
                                BookmarkList _ _ h ->
                                    h

                                _ ->
                                    False

                        remoteTask : Task.Task RequestError (List DiagramItem)
                        remoteTask =
                            Request.items (Session.getIdToken m.session) (pageOffsetAndLimit pageNo) { isPublic = False, isBookmark = True }
                                |> Task.map (\i -> List.filterMap identity i)
                    in
                    Return.return { m | diagramList = BookmarkList Loading pageNo hasMorePage } <| Task.attempt GotBookmarkDiagrams remoteTask
                )

        GetDiagrams ->
            reload

        GotBookmarkDiagrams (Ok diagrams) ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage : Bool
                        hasMorePage =
                            List.length diagrams >= pageSize

                        ( pageNo, allDiagrams ) =
                            case m.diagramList of
                                BookmarkList (Success currentDiagrams) p _ ->
                                    ( p, Success <| List.concat [ currentDiagrams, diagrams ] )

                                BookmarkList _ p _ ->
                                    ( p, Success diagrams )

                                _ ->
                                    ( 1, Success diagrams )
                    in
                    Return.singleton { m | diagramList = BookmarkList allDiagrams pageNo hasMorePage }
                )

        GotBookmarkDiagrams (Err _) ->
            Return.zero

        GetGistDiagrams pageNo ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage : Bool
                        hasMorePage =
                            case m.diagramList of
                                GistList _ _ h ->
                                    h

                                _ ->
                                    False

                        remoteTask : Task.Task RequestError (List DiagramItem)
                        remoteTask =
                            Request.gistItems (Session.getIdToken m.session) (pageOffsetAndLimit pageNo)
                                |> Task.map (\i -> List.filterMap identity i)
                    in
                    Return.return { m | diagramList = GistList Loading pageNo hasMorePage } <| Task.attempt GotGistDiagrams remoteTask
                )

        GotGistDiagrams (Ok diagrams) ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage : Bool
                        hasMorePage =
                            List.length diagrams >= pageSize

                        ( pageNo, allDiagrams ) =
                            case m.diagramList of
                                GistList (Success currentDiagrams) p _ ->
                                    ( p, Success <| List.concat [ currentDiagrams, diagrams ] )

                                GistList _ p _ ->
                                    ( p, Success diagrams )

                                _ ->
                                    ( 1, Success diagrams )
                    in
                    Return.singleton { m | diagramList = GistList allDiagrams pageNo hasMorePage }
                )

        GotGistDiagrams (Err _) ->
            Return.zero

        GotLocalDiagramsJson json ->
            Return.andThen
                (\m ->
                    case m.diagramList of
                        AllList Loading _ _ ->
                            Return.singleton m

                        AllList _ pageNo _ ->
                            let
                                localItems : List DiagramItem
                                localItems =
                                    Result.withDefault [] <|
                                        D.decodeValue (D.list DiagramItem.decoder) json
                            in
                            if Session.isSignedIn m.session && m.isOnline then
                                let
                                    remoteItems : Task.Task RequestError (List DiagramItem)
                                    remoteItems =
                                        Request.allItems (Session.getIdToken m.session) (pageOffsetAndLimit pageNo)
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
                                Return.return
                                    { m
                                        | diagramList =
                                            case m.diagramList of
                                                AllList NotAsked _ _ ->
                                                    AllList Loading 1 False

                                                _ ->
                                                    m.diagramList
                                    }
                                <|
                                    Task.attempt GotDiagrams items

                            else
                                Return.singleton { m | diagramList = AllList (Success localItems) 1 False }

                        _ ->
                            Return.singleton m
                )

        GotDiagrams (Err _) ->
            Return.zero

        GotDiagrams (Ok items) ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage : Bool
                        hasMorePage =
                            List.length items >= pageSize

                        ( remoteData, pageNo ) =
                            case m.diagramList of
                                AllList r p _ ->
                                    ( r, p )

                                _ ->
                                    ( Success [], 1 )
                    in
                    Return.singleton
                        { m
                            | diagramList =
                                if List.isEmpty <| RemoteData.withDefault [] remoteData then
                                    AllList (Success items) 1 hasMorePage

                                else
                                    AllList (RemoteData.andThen (\currentItems -> Success <| List.concat [ currentItems, items ]) remoteData) pageNo hasMorePage
                        }
                )

        Remove diagram ->
            Return.andThen closeDialog
                >> Return.command (removeDiagrams (DiagramItem.encoder diagram))

        RemoveRemote diagramJson ->
            Return.andThen
                (\m ->
                    case D.decodeValue DiagramItem.decoder diagramJson of
                        Ok diagram ->
                            case diagram.location of
                                Just DiagramLocation.Gist ->
                                    case Session.getAccessToken m.session of
                                        Just accessToken ->
                                            Return.return m
                                                (Task.attempt Removed
                                                    (Request.deleteGist (Session.getIdToken m.session)
                                                        accessToken
                                                        (diagram.id |> Maybe.withDefault (DiagramId.fromString "") |> DiagramId.toString)
                                                        |> Task.map identity
                                                    )
                                                )

                                        Nothing ->
                                            -- TODO: Login to github and get an access token.
                                            Return.singleton m

                                _ ->
                                    Return.return m
                                        (Task.attempt Removed
                                            (Request.delete (Session.getIdToken m.session)
                                                (diagram.id |> Maybe.withDefault (DiagramId.fromString "") |> DiagramId.toString)
                                                False
                                                |> Task.map identity
                                            )
                                        )

                        Err _ ->
                            Return.singleton m
                )

        Removed (Err _) ->
            Return.zero

        Removed (Ok _) ->
            reload

        Reload ->
            reload

        Bookmark diagram ->
            Return.andThen
                (\m ->
                    let
                        ( remoteData, pageNo, hasMorePage ) =
                            case m.diagramList of
                                AllList r p h ->
                                    ( r, p, h )

                                GistList r p h ->
                                    ( r, p, h )

                                PublicList r p h ->
                                    ( r, p, h )

                                BookmarkList r p h ->
                                    ( r, p, h )

                        diagramList : List DiagramItem
                        diagramList =
                            RemoteData.withDefault [] remoteData |> updateIf (\item -> item.id == diagram.id) (\item -> { item | isBookmark = not item.isBookmark })
                    in
                    Return.return { m | diagramList = createDiagramList m.diagramList diagramList pageNo hasMorePage }
                        (Task.attempt Bookmarked
                            (Request.bookmark (Session.getIdToken m.session)
                                (case diagram.id of
                                    Just id ->
                                        DiagramId.toString id

                                    Nothing ->
                                        ""
                                )
                                (not diagram.isBookmark)
                                |> Task.map (\_ -> ())
                            )
                        )
                )

        Import ->
            Return.command <| Select.file [ "application/json" ] ImportFile

        ImportFile file ->
            Return.command <| Task.perform ImportComplete <| File.toString file

        ImportComplete json ->
            case DiagramItem.stringToList json of
                Ok diagrams ->
                    Return.command <| importDiagram <| DiagramItem.listToValue diagrams

                Err _ ->
                    Return.zero

        Export ->
            Return.andThen
                (\m ->
                    case m.diagramList of
                        AllList (Success diagrams) _ _ ->
                            Return.return m <| Download.string "textusm.json" "application/json" <| DiagramItem.listToString diagrams

                        _ ->
                            Return.singleton m
                )

        CloseDialog ->
            Return.andThen closeDialog

        ShowConfirmDialog d ->
            Return.andThen <|
                \m ->
                    Return.singleton
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

        _ ->
            Return.zero
