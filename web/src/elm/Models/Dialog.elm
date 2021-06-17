module Models.Dialog exposing (ConfirmDialog(..))


type ConfirmDialog msg
    = Hide
    | Show { title : String, message : String, ok : msg, cancel : msg }
