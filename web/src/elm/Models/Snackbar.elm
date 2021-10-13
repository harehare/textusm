module Models.Snackbar exposing (Snackbar(..))


type Snackbar msg
    = Show (Model msg)
    | Hide


type alias Model msg =
    { message : String
    , text : String
    , action : msg
    }
