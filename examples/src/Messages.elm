module Messages exposing (..)

{-| This does exactly the same thing as the `Basic` example, but it
uses `Debouncer.Messages` instead of `Debouncer.Basic`. This simplifies
your code in the (common) case where what you're debouncing is your
own `Msg` type. (You would want `Debouncer.Basic` in other cases, since
it is more general).
-}

import Debouncer.Messages as Debouncer exposing (Debouncer, provideInput)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Time exposing (Time)


type alias Model =
    { quietForOneSecond : Debouncer Msg
    , messages : List String
    }


quietForOneSecondConfig : Debouncer.Config Msg
quietForOneSecondConfig =
    { emitWhenUnsettled = Nothing
    , emitWhileUnsettled = Nothing
    , settleWhenQuietFor = 1 * Time.second
    , accumulator = \input accum -> Just input
    }


init : ( Model, Cmd Msg )
init =
    ( { quietForOneSecond = Debouncer.init quietForOneSecondConfig
      , messages = []
      }
    , Cmd.none
    )


type Msg
    = MsgQuietForOneSecond (Debouncer.Msg Msg)
    | DoSomething


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MsgQuietForOneSecond subMsg ->
            let
                ( subModel, cmd, emittedMsg ) =
                    Debouncer.update MsgQuietForOneSecond subMsg model.quietForOneSecond

                updatedModel =
                    { model | quietForOneSecond = subModel }
            in
                case emittedMsg of
                    Nothing ->
                        ( updatedModel, cmd )

                    Just emitted ->
                        update emitted updatedModel
                            |> Tuple.mapSecond (\cmd2 -> Cmd.batch [ cmd, cmd2 ])

        DoSomething ->
            ( { model | messages = model.messages ++ [ "I did something" ] }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    div [ style [ ( "margin", "1em" ) ] ]
        [ button
            [ DoSomething
                |> provideInput
                |> MsgQuietForOneSecond
                |> onClick
            ]
            [ text "Click here repeatedly." ]
        , p [] [ text " I'll add a message below once you stop clicking for one second." ]
        , model.messages
            |> List.map (\message -> p [] [ text message ])
            |> div []
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }