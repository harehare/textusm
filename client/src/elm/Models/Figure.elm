module Models.Figure exposing (Children(..), Color, ColorSettings, Comment, Item, ItemType(..), Model, Msg(..), Settings, Size, UsmSvg)

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
    }


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
    | SelectLine String
    | StartPinch Float
