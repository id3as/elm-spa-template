# elm-spa-template

## Intent of the Project

This project is something of a playground for the wonderful [Elm language](elm-lang.org) and how to build SPAs in particular.  Much of the structure is taken from the excellent [elm-mdl](https://github.com/debois/elm-mdl) and its [live demo](https://debois.github.io/elm-mdl/) in particular.

I used the tabs infrastrucutre in the mdl-demo as a starting point.  It uses an array of tab details to set up the many contained tabs.  A "real" application needs a little more flexibility than that and in particualr we need to be able to deal with who some common state (who is logged in etc).  I very much wanted the contained tabs to not store any state that was not directly their own, so have experimented with injecting "context information" into the calls to their views.

There is a major convenience in having the tabs boilerplate defined as concisely as possible. Here is one such boilerplate for the tabs:

```elm
tabList : List Tab
tabList =
    [ { info = { tabName = "Tables", tabUrl = "tables", requiredRole = Auth.User }, tabViewMap = tableTabViewMap }
    , { info = { tabName = "Puppies", tabUrl = "puppies", requiredRole = Auth.Admin }, tabViewMap = .tabPuppies >> Tabs.Puppies.view >> App.map PuppiesMsg }
    , { info = { tabName = "Encoders", tabUrl = "encoders", requiredRole = Auth.User }, tabViewMap = .tabEncoders >> Tabs.Encoders.view >> App.map EncodersMsg }
    , { info = logonTabInfo, tabViewMap = logonTabViewMap }
    ]
```

As we are strongly typed and lists must be homogeneous, the tabViewMap element must all be of the same type (in this case ```Model -> Html Msg```)  Taking the case of the Logon tab, it would be nice to be able to say why we ended up there if, for example, we have been redirected there while trying to access a different tab for which we do not have permission.

This is done as follows:
```elm
logonTabViewMap : Model -> Html Msg
logonTabViewMap model =
    let
        desiredTabInfo =
            -- We would really like to just pull the info from the static tabInfoArray
            -- The problem is that creates a circular dependency as this LogonTabViewMap is part
            -- of the tabList.
            -- Instead we copy the tabInfoArray (without the viewmap functions) into the model
            -- on startup and that breaks the self-reference.
            Array.get model.desiredTab model.tabInfoArray |> Maybe.withDefault logonTabInfo
    in
        let
            viewWithInjectedArgs =
                Tabs.Logon.view (model.selectedTab /= model.desiredTab) desiredTabInfo.tabName desiredTabInfo.requiredRole
        in
            .tabLogon model |> viewWithInjectedArgs |> App.map LogonMsg
```
(As an aside, if you do have the circualr reference it compiles just fine but crashes when you load the SPA with the generated Javascript referencing the array the live before it sets it - fair enough really!)

