module Utils exposing (debugDumpModel, modelNoMdl, indexOf, msg2cmd)

import String
import Html exposing (..)
import Task exposing (..)


-- Debug dump of model withouth the mdl clutter


debugDumpModel : { b | mdl : a } -> Html msg
debugDumpModel model =
    div []
        [ hr [] []
        , h5 [] [ text "Debug dump of model" ]
        , text <| modelNoMdl model
        ]


modelNoMdl : { b | mdl : a } -> String
modelNoMdl model =
    let
        modelStr =
            toString model

        mdlStr =
            toString model.mdl
    in
        String.join "..." <| String.split mdlStr modelStr


msg2cmd : a -> Cmd a
msg2cmd msg =
    Task.perform identity identity (Task.succeed msg)


indexOf : a -> List a -> Maybe Int
indexOf elem list =
    indexOf' elem list 0


indexOf' : a -> List a -> Int -> Maybe Int
indexOf' elem list index =
    case list of
        [] ->
            Nothing

        x :: xs ->
            if x == elem then
                Just index
            else
                indexOf' elem xs (index + 1)
