module Translations exposing (..)


type Lang
    = En
    | Ja


fromString : String -> Lang
fromString lang =
    case lang of
        "ja" ->
            Ja

        _ ->
            En


toolTipNewFile : Lang -> String
toolTipNewFile lang =
    case lang of
        Ja ->
            "新規作成"

        _ ->
            "New File"


toolTipOpenFile : Lang -> String
toolTipOpenFile lang =
    case lang of
        Ja ->
            "開く"

        _ ->
            "Open File"


toolTipSave : Lang -> String
toolTipSave lang =
    case lang of
        Ja ->
            "保存"

        _ ->
            "Save"


toolTipExport : Lang -> String
toolTipExport lang =
    case lang of
        Ja ->
            "エクスポート"

        _ ->
            "Export"


toolTipSettings : Lang -> String
toolTipSettings lang =
    case lang of
        Ja ->
            "設定"

        _ ->
            "Settings"


toolTipTags : Lang -> String
toolTipTags lang =
    case lang of
        Ja ->
            "タグ"

        _ ->
            "Tags"


toolTipShare : Lang -> String
toolTipShare lang =
    case lang of
        Ja ->
            "共有"

        _ ->
            "Share"


toolTipHelp : Lang -> String
toolTipHelp lang =
    case lang of
        Ja ->
            "ヘルプ"

        _ ->
            "Help"


messageFailed : Lang -> String
messageFailed lang =
    case lang of
        Ja ->
            "失敗しました。"

        _ ->
            "Failed."


messageRequestTimeout : Lang -> String
messageRequestTimeout lang =
    case lang of
        Ja ->
            "リクエストがタイムアウトしました。"

        _ ->
            "Request timeout."


messageNetworkError : Lang -> String
messageNetworkError lang =
    case lang of
        Ja ->
            "ネットワークエラーが発生しました。"

        _ ->
            "Network error."


messageSuccessfullySaved : Lang -> String -> String
messageSuccessfullySaved lang title =
    case lang of
        Ja ->
            "\"" ++ title ++ "\" を保存しました。"

        _ ->
            "Successfully \"" ++ title ++ "\" saved."


messageFailedSaved : Lang -> String -> String
messageFailedSaved lang title =
    case lang of
        Ja ->
            "\"" ++ title ++ "\" の保存に失敗しました。"

        _ ->
            "Failed \"" ++ title ++ "\" saved."
