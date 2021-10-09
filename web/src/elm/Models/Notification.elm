module Models.Notification exposing
    ( Notification(..)
    , NotificationState(..)
    , showErrorNotifcation
    , showInfoNotifcation
    , showWarningNotifcation
    )


type NotificationState
    = Show Notification
    | Hide


type Notification
    = Info String
    | Error String
    | Warning String


showErrorNotifcation : String -> NotificationState
showErrorNotifcation message =
    Show <| Error message


showWarningNotifcation : String -> NotificationState
showWarningNotifcation message =
    Show <| Warning message


showInfoNotifcation : String -> NotificationState
showInfoNotifcation message =
    Show <| Info message
