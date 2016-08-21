module Tabs.Logon exposing (Model, Msg(PostFail, PostSucceed), model, update, view)

import Html.App as App
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
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



-- CheckCredentials


checkCredentials : Bool -> String -> String -> Cmd Msg
checkCredentials fakeAuth username password =
    let
        authTask =
            case fakeAuth of
                True ->
                    fakeCheckCredentials username password

                False ->
                    httpCheckCredentials' username password
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


httpCheckCredentials' : String -> String -> Task.Task Http.Error Auth.UserAuth
httpCheckCredentials' username password =
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
    Options.div [ Options.css "margin-left" "20px" ]
        [ header
            [ style
                [ ( "text-align", "center" )
                , ( "margin-top", "4em" )
                ]
            ]
            [ h1
                [ style
                    [ ( "font-weight", "300" )
                    , ( "color", "#636363" )
                    ]
                ]
                [ text "Fake Logon" ]
            , h3
                [ style
                    [ ( "font-weight", "300" )
                    , ( "color", "#4a89dc" )
                    ]
                ]
                [ text "Elm SPA" ]
            ]
        , Html.form [ formCss, onSubmit CheckCredentials ]
            [ Options.div
                [ Options.center ]
                [ if isRedirect then
                    div []
                        [ text <|
                            "In order to access the "
                                ++ targetTabName
                                ++ " tab, you need to logon as a user in the "
                                ++ (toString requiredRole)
                                ++ " role."
                        , hr [] []
                        ]
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
                    [ Textfield.label "Password"
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
            ]
        , Options.div
            []
            [ text <| "There are two users available:" ]
        , ul []
            [ li [] [ text "user" ]
            , li [] [ text "admin" ]
            ]
        , text "any password will do..."
          -- Debug dump of model withouth the mdl clutter
        , Utils.debugDumpModel model
        ]



-- Json encode /decode


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


formCss =
    style
        [ ( "width", "380px" )
        , ( "margin", "4em auto" )
        , ( "padding", "3em 2em 2em 2em" )
        , ( "background", "#fafafa" )
        , ( "border", "1px solid #ebebeb" )
        , ( "box-shadow", "rgba(0,0,0,0.14902) 0px 1px 1px 0px,rgba(0,0,0,0.09804) 0px 1px 2px 0px" )
        ]
