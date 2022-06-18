module Models.Window exposing
    ( Window
    , fullscreen
    , init
    , isDisplayBoth
    , isDisplayEditor
    , isDisplayPreview
    , isFullscreen
    , isResizing
    , position
    , resized
    , resizing
    , showEditor
    , showEditorAndPreview
    , startResizing
    , toggle
    )


type alias Window =
    { position : Int
    , state : State
    }


type State
    = Editor
    | Preview
    | Both
    | Fullscreen
    | Resize Int


init : Int -> Window
init p =
    { position = p, state = Both }


startResizing : Window -> Int -> Window
startResizing w pos =
    { w | state = Resize pos }


resizing : Window -> Int -> Window
resizing window pos =
    case window.state of
        Resize prevPos ->
            { window | position = window.position + pos - prevPos, state = Resize pos }

        _ ->
            window


resized : Window -> Window
resized window =
    { window | state = Both }


toggle : Window -> Window
toggle window =
    case window.state of
        Preview ->
            { window | state = Editor }

        Editor ->
            { window | state = Preview }

        _ ->
            window


showEditor : Window -> Window
showEditor window =
    { window | state = Editor }


fullscreen : Window -> Window
fullscreen window =
    { window | state = Fullscreen }


showEditorAndPreview : Window -> Window
showEditorAndPreview window =
    { window | state = Both }


isFullscreen : Window -> Bool
isFullscreen window =
    case window.state of
        Fullscreen ->
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


isDisplayBoth : Window -> Bool
isDisplayBoth window =
    case window.state of
        Both ->
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


position : Window -> Int
position window =
    window.position
