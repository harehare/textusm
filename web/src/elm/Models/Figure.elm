module Models.Figure exposing (Children(..), Color, ColorSettings, Comment, FigureType(..), Item, ItemType(..), Model, Msg(..), Settings, Size, UsmSvg, toString)

import Browser.Dom exposing (Viewport)


type alias Model =
    { items : List Item
    , hierarchy : Int
    , width : Int
    , height : Int
    , countByHierarchy : List Int
    , countByTasks : List Int
    , svg : UsmSvg
    , moveStart : Bool
    , x : Int
    , y : Int
    , moveX : Int
    , moveY : Int
    , fullscreen : Bool
    , settings : Settings
    , error : Maybe String
    , comment : Maybe Comment
    , showZoomControl : Bool
    , touchDistance : Maybe Float
    , figureType : FigureType
    , labels : List String
    }


type FigureType
    = UserStoryMap
    | OpportunityCanvas
    | BusinessModelCanvas


type Children
    = Children (List Item)


type alias Item =
    { text : String
    , comment : Maybe String
    , itemType : ItemType
    , children : Children
    }


type ItemType
    = Activities
    | Tasks
    | Stories Int
    | Comments


type alias UsmSvg =
    { width : Int
    , height : Int
    , scale : Float
    }


type alias Comment =
    { x : Int
    , y : Int
    , text : String
    }


type alias Settings =
    { font : String
    , size : Size
    , color : ColorSettings
    , backgroundColor : String
    }


type alias ColorSettings =
    { activity : Color
    , task : Color
    , story : Color
    , comment : Color
    , line : String
    , label : String
    }


type alias Color =
    { color : String
    , backgroundColor : String
    }


type alias Size =
    { width : Int
    , height : Int
    }


type Msg
    = NoOp
    | Init Settings Viewport String
    | OnChangeText String
    | ZoomIn
    | ZoomOut
    | PinchIn Float
    | PinchOut Float
    | Stop
    | Start Int Int
    | Move Int Int
    | ToggleFullscreen
    | ShowComment Comment
    | HideComment
    | OnResize Int Int
    | StartPinch Float
    | ItemClick Item


toString : List Item -> String
toString =
    let
        itemsToString : Int -> List Item -> String
        itemsToString hierarcy items =
            let
                itemToString : Item -> Int -> String
                itemToString i hi =
                    case i.comment of
                        Just c ->
                            String.repeat hi "    " ++ i.text ++ ": " ++ c

                        Nothing ->
                            String.repeat hi "    " ++ i.text
            in
            items
                |> List.map
                    (\item ->
                        case item.children of
                            Children [] ->
                                itemToString item hierarcy

                            Children c ->
                                itemToString item hierarcy ++ "\n" ++ itemsToString (hierarcy + 1) c
                    )
                |> String.join "\n"
    in
    itemsToString 0
