module Models.Window exposing
    ( State
    , Window
    , fullscreen
    , init
    , isDisplayBoth
    , isDisplayEditor
    , isDisplayPreview
    , isFullscreen
    , isResizing
    , resized
    , resizing
    , showEditor
    , showEditorAndPreview
    , startResizing
    , toggle
    )


type State
    = Editor
    | Preview
    | Both
    | Fullscreen
    | Resize Int


type alias Window =
    { position : Int
    , state : State
    }


fullscreen : Window -> Window
fullscreen window =
    { window | state = Fullscreen }


init : Int -> Window
init p =
    { position = p, state = Both }


isDisplayBoth : Window -> Bool
isDisplayBoth window =
    case window.state of
        Both ->
            True

        _ ->
            False


isDisplayEditor : Window -> Bool
isDisplayEditor window =
    case window.state of
        Editor ->
            True

        _ ->
            False


isDisplayPreview : Window -> Bool
isDisplayPreview window =
    case window.state of
        Preview ->
            True

        _ ->
            False


isFullscreen : Window -> Bool
isFullscreen window =
    case window.state of
        Fullscreen ->
            True

        _ ->
            False


isResizing : Window -> Bool
isResizing window =
    case window.state of
        Resize _ ->
            True

        _ ->
            False


resized : Window -> Window
resized window =
    { window | state = Both }


resizing : Window -> Int -> Window
resizing window pos =
    case window.state of
        Resize prevPos ->
            { window | position = window.position + pos - prevPos, state = Resize pos }

        _ ->
            window


showEditor : Window -> Window
showEditor window =
    { window | state = Editor }


showEditorAndPreview : Window -> Window
showEditorAndPreview window =
    { window | state = Both }


startResizing : Window -> Int -> Window
startResizing w pos =
    { w | state = Resize pos }


toggle : Window -> Window
toggle window =
    case window.state of
        Editor ->
            { window | state = Preview }

        Preview ->
            { window | state = Editor }

        _ ->
            window
