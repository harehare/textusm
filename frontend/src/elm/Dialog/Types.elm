module Dialog.Types exposing (ConfirmDialog(..))


type ConfirmDialog msg
    = Hide
    | Show { title : String, message : String, ok : msg, cancel : msg }
