module Message exposing
    ( Lang(..)
    , Message
    , langFromString
    , messagEerrorOccurred
    , messageBadRequest
    , messageFailedLoadSettings
    , messageFailedPublished
    , messageFailedRevokeToken
    , messageFailedSaveSettings
    , messageFailedSaved
    , messageFailedSharing
    , messageImportCompleted
    , messageInternalServerError
    , messageInvalidUrl
    , messageNetworkError
    , messageNotAuthorized
    , messageNotFound
    , messagePublished
    , messageSuccessfullySaved
    , messageTimeout
    , messageUnknown
    , messageUrlExpired
    , toLangString
    , toolTipCopy
    , toolTipEditFile
    , toolTipExport
    , toolTipHelp
    , toolTipImport
    , toolTipNewFile
    , toolTipOpenFile
    , toolTipPrivate
    , toolTipPublic
    , toolTipSave
    , toolTipSettings
    , toolTipShare
    )


type Lang
    = En
    | Ja


type alias Message =
    Lang -> String


langFromString : String -> Lang
langFromString lang =
    case lang of
        "ja" ->
            Ja

        _ ->
            En


toLangString : Lang -> String
toLangString lang =
    case lang of
        Ja ->
            "ja"

        _ ->
            "en"


messagEerrorOccurred : Lang -> String
messagEerrorOccurred lang =
    case lang of
        Ja ->
            "エラーが発生しました"

        _ ->
            "An error occurred"


messageBadRequest : Lang -> String
messageBadRequest lang =
    case lang of
        Ja ->
            "不正なリクエストです"

        _ ->
            "Bad request"


messageFailedPublished : Lang -> String
messageFailedPublished lang =
    case lang of
        Ja ->
            "公開設定の変更に失敗しました"

        _ ->
            "Failed to change publishing settings"


messageFailedRevokeToken : Lang -> String
messageFailedRevokeToken lang =
    case lang of
        Ja ->
            "トークンの失効処理に失敗しました"

        _ ->
            "Failed to revoke the token"


messageFailedLoadSettings : Lang -> String
messageFailedLoadSettings lang =
    case lang of
        Ja ->
            "設定の読み込みに失敗しました"

        _ ->
            "Failed to load settings"


messageFailedSaveSettings : Lang -> String
messageFailedSaveSettings lang =
    case lang of
        Ja ->
            "設定の保存に失敗しました"

        _ ->
            "Failed to save settings"


messageFailedSaved : Lang -> String
messageFailedSaved lang =
    case lang of
        Ja ->
            "保存に失敗しました"

        _ ->
            "Failed saved"


messageFailedSharing : Lang -> String
messageFailedSharing lang =
    case lang of
        Ja ->
            "共有 URL の生成に失敗しました"

        _ ->
            "Failed to generate URL for sharing"


messageImportCompleted : Lang -> String
messageImportCompleted lang =
    case lang of
        Ja ->
            "インポートが完了しました"

        _ ->
            "Import completed"


messageInternalServerError : Lang -> String
messageInternalServerError lang =
    case lang of
        Ja ->
            "システムエラーが発生しました"

        _ ->
            "Internal server error has occurred"


messageInvalidUrl : Lang -> String
messageInvalidUrl lang =
    case lang of
        Ja ->
            "不正な URL にアクセスされました"

        _ ->
            "Invalid URL"


messageNetworkError : Lang -> String
messageNetworkError lang =
    case lang of
        Ja ->
            "ネットワークエラーが発生しました"

        _ ->
            "Network error"


messageNotAuthorized : Lang -> String
messageNotAuthorized lang =
    case lang of
        Ja ->
            "権限がありません"

        _ ->
            "Not authorized"


messageNotFound : Lang -> String
messageNotFound lang =
    case lang of
        Ja ->
            "見つかりませんでした"

        _ ->
            "Not found"


messagePublished : Lang -> String
messagePublished lang =
    case lang of
        Ja ->
            "公開しました"

        _ ->
            "Published"


messageSuccessfullySaved : Lang -> String
messageSuccessfullySaved lang =
    case lang of
        Ja ->
            "保存しました"

        _ ->
            "Successfully saved"


messageTimeout : Lang -> String
messageTimeout lang =
    case lang of
        Ja ->
            "リクエストがタイムアウトしました"

        _ ->
            "Request timeout"


messageUnknown : Lang -> String
messageUnknown lang =
    case lang of
        Ja ->
            "システムエラーが発生しました"

        _ ->
            "Unknown error has occurred"


messageUrlExpired : Lang -> String
messageUrlExpired lang =
    case lang of
        Ja ->
            "URL の有効期限が切れました"

        _ ->
            "URL has expired"


toolTipPrivate : Lang -> String
toolTipPrivate lang =
    case lang of
        Ja ->
            "非公開"

        _ ->
            "Private"


toolTipPublic : Lang -> String
toolTipPublic lang =
    case lang of
        Ja ->
            "公開"

        _ ->
            "Public"


toolTipCopy : Lang -> String
toolTipCopy lang =
    case lang of
        Ja ->
            "コピー"

        _ ->
            "Copy"


toolTipExport : Lang -> String
toolTipExport lang =
    case lang of
        Ja ->
            "エクスポート"

        _ ->
            "Export"


toolTipHelp : Lang -> String
toolTipHelp lang =
    case lang of
        Ja ->
            "ヘルプ"

        _ ->
            "Help"


toolTipImport : Lang -> String
toolTipImport lang =
    case lang of
        Ja ->
            "インポート"

        _ ->
            "Import"


toolTipNewFile : Lang -> String
toolTipNewFile lang =
    case lang of
        Ja ->
            "新規作成"

        _ ->
            "New File"


toolTipEditFile : Lang -> String
toolTipEditFile lang =
    case lang of
        Ja ->
            "編集"

        _ ->
            "Edit File"


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


toolTipSettings : Lang -> String
toolTipSettings lang =
    case lang of
        Ja ->
            "設定"

        _ ->
            "Settings"


toolTipShare : Lang -> String
toolTipShare lang =
    case lang of
        Ja ->
            "共有"

        _ ->
            "Share"
