module Page.List.DiagramList exposing
    ( DiagramList(..)
    , DiagramListData
    , allList
    , append
    , bookmarkList
    , create
    , gistList
    , hasMorePageInBookmarkList
    , hasMorePageInGistList
    , hasMorePageInPublicList
    , isAllList
    , isBookMarkList
    , isGistList
    , isPublicList
    , loading
    , notAsked
    , publicList
    , unwrap
    )

import Models.Diagram.Item exposing (DiagramItem)
import RemoteData exposing (RemoteData(..), WebData)


pageSize : Int
pageSize =
    30


type DiagramList
    = AllList DiagramListData Int Bool
    | PublicList DiagramListData Int Bool
    | BookmarkList DiagramListData Int Bool
    | GistList DiagramListData Int Bool


type alias DiagramListData =
    WebData (List DiagramItem)


loading : DiagramList -> DiagramList
loading diagramList =
    case diagramList of
        AllList NotAsked _ _ ->
            AllList Loading 1 False

        _ ->
            diagramList


bookmarkList : { list : DiagramListData, pageNo : Int, hasMorePage : Bool } -> DiagramList
bookmarkList { list, pageNo, hasMorePage } =
    BookmarkList list pageNo hasMorePage


gistList : { list : DiagramListData, pageNo : Int, hasMorePage : Bool } -> DiagramList
gistList { list, pageNo, hasMorePage } =
    GistList list pageNo hasMorePage


publicList : { list : DiagramListData, pageNo : Int, hasMorePage : Bool } -> DiagramList
publicList { list, pageNo, hasMorePage } =
    PublicList list pageNo hasMorePage


allList : { list : DiagramListData, pageNo : Int, hasMorePage : Bool } -> DiagramList
allList { list, pageNo, hasMorePage } =
    AllList list pageNo hasMorePage


notAsked : DiagramList
notAsked =
    AllList NotAsked 1 False


create : DiagramList -> List DiagramItem -> Int -> Bool -> DiagramList
create diagramList data page hasMorePage =
    case diagramList of
        AllList _ _ _ ->
            AllList (Success data) page hasMorePage

        PublicList _ _ _ ->
            PublicList (Success data) page hasMorePage

        BookmarkList _ _ _ ->
            BookmarkList (Success data) page hasMorePage

        GistList _ _ _ ->
            GistList (Success data) page hasMorePage


append : DiagramList -> List DiagramItem -> DiagramList
append currentDiagrams diagrams =
    let
        hasMorePage : Bool
        hasMorePage =
            List.length diagrams >= pageSize
    in
    case currentDiagrams of
        PublicList (Success d) p _ ->
            PublicList (Success <| List.concat [ d, diagrams ]) p hasMorePage

        PublicList _ p _ ->
            PublicList (Success diagrams) p hasMorePage

        GistList (Success d) p _ ->
            PublicList (Success <| List.concat [ d, diagrams ]) p hasMorePage

        GistList _ p _ ->
            PublicList (Success diagrams) p hasMorePage

        AllList (Success d) p _ ->
            AllList (Success <| List.concat [ d, diagrams ]) p hasMorePage

        AllList _ p _ ->
            AllList (Success diagrams) p hasMorePage

        BookmarkList (Success d) p _ ->
            BookmarkList (Success <| List.concat [ d, diagrams ]) p hasMorePage

        BookmarkList _ p _ ->
            BookmarkList (Success diagrams) p hasMorePage


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


hasMorePageInGistList : DiagramList -> Bool
hasMorePageInGistList list =
    case list of
        GistList _ _ h ->
            h

        _ ->
            False


hasMorePageInBookmarkList : DiagramList -> Bool
hasMorePageInBookmarkList diagramList =
    case diagramList of
        BookmarkList _ _ h ->
            h

        _ ->
            False


hasMorePageInPublicList : DiagramList -> Bool
hasMorePageInPublicList diagramList =
    case diagramList of
        PublicList _ _ h ->
            h

        _ ->
            False


unwrap : DiagramList -> { list : DiagramListData, pageNo : Int, hasMorePage : Bool }
unwrap diagramList =
    case diagramList of
        AllList r p h ->
            { list = r, pageNo = p, hasMorePage = h }

        GistList r p h ->
            { list = r, pageNo = p, hasMorePage = h }

        PublicList r p h ->
            { list = r, pageNo = p, hasMorePage = h }

        BookmarkList r p h ->
            { list = r, pageNo = p, hasMorePage = h }
