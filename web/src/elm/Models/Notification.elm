module Models.Notification exposing
    ( Model(..)
    , Notification(..)
    , showErrorNotifcation
    , showInfoNotifcation
    , showWarningNotifcation
    )


type Notification
    = Show Model
    | Hide


type Model
    = Info String
    | Error String
    | Warning String


showErrorNotifcation : String -> Notification
showErrorNotifcation message =
    Show <| Error message


showWarningNotifcation : String -> Notification
showWarningNotifcation message =
    Show <| Warning message


showInfoNotifcation : String -> Notification
showInfoNotifcation message =
    Show <| Info message
