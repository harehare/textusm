module Models.Notification exposing
    ( Model(..)
    , Notification(..)
    , showErrorNotifcation
    , showInfoNotifcation
    , showWarningNotifcation
    )


type Model
    = Info String
    | Error String
    | Warning String


type Notification
    = Show Model
    | Hide


showErrorNotifcation : String -> Notification
showErrorNotifcation message =
    Show <| Error message


showInfoNotifcation : String -> Notification
showInfoNotifcation message =
    Show <| Info message


showWarningNotifcation : String -> Notification
showWarningNotifcation message =
    Show <| Warning message
