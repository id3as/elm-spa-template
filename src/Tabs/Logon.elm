module Tabs.Logon exposing (Model, Msg(PostFail, PostSucceed), model, update, view)

import Html.App as App
import Html exposing (..)
import Material
import Material.Textfield as Textfield
import Material.Button as Button
import Material.Options as Options exposing (nop)
import Task
import Http
import Json.Decode as Json
import Json.Decode.Pipeline as JsonPipeline
import Json.Encode as JS
import Auth
import Utils


main : Program Never
main =
    App.program
        { init = ( model, Cmd.none )
        , view = view False "" Auth.None
        , subscriptions = always Sub.none
        , update = update
        }



-- HTTP


checkCredentials : Bool -> String -> String -> Cmd Msg
checkCredentials fakeAuth username password =
    let
        authTask =
            case fakeAuth of
                True ->
                    fakeCheckCredentials username password

                False ->
                    checkCredentials' username password
    in
        Task.perform PostFail PostSucceed authTask


fakeCheckCredentials : String -> String -> Task.Task Http.Error Auth.UserAuth
fakeCheckCredentials username password =
    let
        userAuth =
            case username of
                "user" ->
                    Auth.UserAuth username "123" [ Auth.User ]

                "admin" ->
                    Auth.UserAuth username "456" [ Auth.User, Auth.Admin ]

                _ ->
                    Auth.none
    in
        Task.succeed userAuth


checkCredentials' : String -> String -> Task.Task Http.Error Auth.UserAuth
checkCredentials' username password =
    Http.send Http.defaultSettings
        { verb = "POST"
        , headers =
            [ ( "Content-Type", "application/json" )
            , ( "Accept", "application/json" )
            ]
        , url = "https://127.0.0.1:3000/users/logon"
        , body =
            Http.string <| encodeAuthRequest username password
        }
        |> Http.fromJson decodeAuthResponse


encodeAuthRequest : String -> String -> String
encodeAuthRequest username password =
    JS.encode 0 <|
        JS.object
            [ ( "username", JS.string username )
            , ( "password", JS.string password )
            ]


decodeAuthResponse : Json.Decoder Auth.UserAuth
decodeAuthResponse =
    JsonPipeline.decode Auth.UserAuth
        |> JsonPipeline.required "username" Json.string
        |> JsonPipeline.required "sessionId" Json.string
        |> JsonPipeline.required "roles" (Json.list decodeRole)


decodeRole : Json.Decoder Auth.Role
decodeRole =
    Json.map strToRole Json.string


strToRole : String -> Auth.Role
strToRole str =
    case str of
        "admin" ->
            Auth.Admin

        "user" ->
            Auth.User

        _ ->
            Auth.None



-- Model


type alias Model =
    { username : String
    , password : String
    , fakeAuth : Bool
    , mdl : Material.Model
    }


model : Model
model =
    { username = "admin"
    , password = ""
    , fakeAuth = True
    , mdl = Material.model
    }



-- Update


type Msg
    = CheckCredentials
    | PasswordChange String
    | UsernameChange String
    | MDL (Material.Msg Msg)
    | PostSucceed Auth.UserAuth
    | PostFail Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CheckCredentials ->
            ( model, checkCredentials model.fakeAuth model.username model.password )

        PasswordChange newPassword ->
            ( { model | password = newPassword }, Cmd.none )

        UsernameChange newUsername ->
            ( { model | username = newUsername }, Cmd.none )

        PostSucceed userAuth ->
            ( model, Cmd.none )

        PostFail _ ->
            ( model, Cmd.none )

        MDL action' ->
            Material.update action' model



-- VIEW


view : Bool -> String -> Auth.Role -> Model -> Html Msg
view isRedirect targetTabName requiredRole model =
    div []
        [ h4 []
            [ text "hello" ]
        , Options.div []
            [ if Debug.log "isRedirect" isRedirect then
                text <| "You've ended up here as you need " ++ (toString requiredRole) ++ " permissions to access the " ++ targetTabName ++ " tab"
              else
                text ""
            ]
        , Options.div
            [ Options.center ]
            [ Textfield.render
                MDL
                [ 0 ]
                model.mdl
                [ Textfield.label "Username"
                , Textfield.floatingLabel
                , Textfield.autofocus
                , Textfield.value model.username
                , Textfield.onInput UsernameChange
                , Textfield.text'
                ]
            ]
        , Options.div
            [ Options.center ]
            [ Textfield.render
                MDL
                [ 1 ]
                model.mdl
                [ Textfield.label "Enter password"
                , Textfield.floatingLabel
                , Textfield.onInput PasswordChange
                , Textfield.password
                ]
            ]
        , Options.div
            [ Options.center ]
            [ Button.render MDL
                [ 2 ]
                model.mdl
                [ Button.raised
                , Button.colored
                , Button.onClick CheckCredentials
                ]
                [ text "Login" ]
            ]
          -- Debug dump of model withouth the mdl clutter
        , Utils.debugDumpModel model
        ]
