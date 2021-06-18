module Models.Dialog exposing (ConfirmDialog(..), display)


type ConfirmDialog msg
    = Hide
    | Show { title : String, message : String, ok : msg, cancel : msg }


display : ConfirmDialog msg -> Bool
display d =
    case d of
        Hide ->
            False

        Show _ ->
            True
