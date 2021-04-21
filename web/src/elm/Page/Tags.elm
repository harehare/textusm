module Page.Tags exposing (Model, Msg(..), init, update, view)

import Browser.Dom as Dom
import Events
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (autofocus, class, id, placeholder, style)
import Html.Events exposing (onClick, onInput)
import List.Extra exposing (last)
import Return as Return exposing (Return)
import Task
import Views.Icon as Icon


type alias Tag =
    String


type alias Model =
    { tags : List Tag
    , editTag : Tag
    , deleteTag : Maybe Tag
    }


type Msg
    = NoOp
    | EditTag Tag
    | AddOrDeleteTag Int Bool
    | DeleteTag String


init : List Tag -> ( Model, Cmd Msg )
init tags =
    Return.singleton (Model tags "" Nothing)


focusInput : Model -> Return Msg Model
focusInput model =
    Return.return model
        (Task.attempt (\_ -> NoOp)
            (Dom.focus "edit-tag")
        )


update : Msg -> Model -> Return Msg Model
update msg model =
    case msg of
        NoOp ->
            Return.singleton model

        EditTag tag ->
            Return.singleton { model | deleteTag = Nothing, editTag = tag }

        AddOrDeleteTag 13 False ->
            if not <| List.member model.editTag model.tags then
                Return.singleton { model | editTag = "", tags = model.tags ++ [ model.editTag ] }
                    |> Return.andThen focusInput

            else
                focusInput model

        AddOrDeleteTag 8 False ->
            case model.deleteTag of
                Just tag ->
                    Return.singleton { model | deleteTag = Nothing, tags = List.filter (\t -> tag /= t) model.tags }
                        |> Return.andThen focusInput

                Nothing ->
                    Return.singleton { model | deleteTag = last model.tags }
                        |> Return.andThen focusInput

        AddOrDeleteTag _ _ ->
            Return.singleton model
                |> Return.andThen focusInput

        DeleteTag tag ->
            Return.singleton { model | deleteTag = Nothing, tags = List.filter (\t -> tag /= t) model.tags }
                |> Return.andThen focusInput


view : Model -> Html Msg
view model =
    div [ class "tags" ]
        [ div
            [ class "flex items-center flex-wrap w-full border-main"
            , style "adding" "8px"
            ]
          <|
            List.map (tagView model.deleteTag) (List.filter (String.isEmpty >> not) model.tags)
                ++ [ input
                        [ class "input"
                        , id "edit-tag"
                        , style "width" "150px"
                        , style "background-color" "transparent"
                        , placeholder "ADD TAG"
                        , Events.onKeyDown AddOrDeleteTag
                        , onInput EditTag
                        , autofocus True
                        ]
                        []
                   ]
        ]


tagView : Maybe Tag -> Tag -> Html Msg
tagView deleteTag tag =
    let
        deleteButton =
            div
                [ onClick (DeleteTag tag)
                , class "flex items-center"
                , style "cursor" "pointer"
                ]
                [ Icon.clear "#333" 20 ]
    in
    case deleteTag of
        Just t ->
            if t == tag then
                div [ class "tag delete-tag" ] [ div [ style "padding-right" "8px" ] [ text tag ], deleteButton ]

            else
                div [ class "tag normal-tag" ] [ div [ style "padding-right" "8px" ] [ text tag ], deleteButton ]

        Nothing ->
            div [ class "tag normal-tag" ] [ div [ style "padding-right" "8px" ] [ text tag ], deleteButton ]
