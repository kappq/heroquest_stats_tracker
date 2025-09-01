import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/uri
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event

@external(javascript, "./heroquest_stats_tracker.ffi.mjs", "get_localstorage")
fn get_localstorage(_key: String) -> Result(decode.Dynamic, Nil) {
  Error(Nil)
}

@external(javascript, "./heroquest_stats_tracker.ffi.mjs", "set_localstorage")
fn set_localstorage(_key: String, _json: String) -> Nil {
  Nil
}

@external(javascript, "./heroquest_stats_tracker.ffi.mjs", "clear_item")
fn clear_item() -> Nil {
  Nil
}

pub fn main() -> Nil {
  let app = lustre.simple(init:, update:, view:)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(
    name: String,
    character: Character,
    body: Int,
    mind: Int,
    attack_dice: Int,
    defend_dice: Int,
    gold: Int,
    equipment: List(String),
  )
}

fn model_to_json(model: Model) -> String {
  json.object([
    #("name", json.string(model.name)),
    #("character", json.string(character_to_string(model.character))),
    #("body", json.int(model.body)),
    #("mind", json.int(model.mind)),
    #("attack_dice", json.int(model.attack_dice)),
    #("defend_dice", json.int(model.defend_dice)),
    #("gold", json.int(model.gold)),
    #("equipment", json.array(model.equipment, of: json.string)),
  ])
  |> json.to_string
}

fn model_from_json(json: decode.Dynamic) -> Result(Model, Nil) {
  let model_decoder = {
    use name <- decode.field("name", decode.string)
    use character <- decode.field("character", decode.string)
    use body <- decode.field("body", decode.int)
    use mind <- decode.field("mind", decode.int)
    use attack_dice <- decode.field("attack_dice", decode.int)
    use defend_dice <- decode.field("defend_dice", decode.int)
    use gold <- decode.field("gold", decode.int)
    use equipment <- decode.field("equipment", decode.list(of: decode.string))

    // let assert Ok(character) = character_from_string(character)
    let character = character_from_string(character) |> result.unwrap(Wizard)

    decode.success(Model(
      name:,
      character:,
      body:,
      mind:,
      attack_dice:,
      defend_dice:,
      gold:,
      equipment:,
    ))
  }

  decode.run(json, model_decoder)
  |> result.replace_error(Nil)
}

type Character {
  Barbarian
  Dwarf
  Elf
  Wizard
}

fn character_to_string(character: Character) -> String {
  case character {
    Barbarian -> "Barbarian"
    Dwarf -> "Dwarf"
    Elf -> "Elf"
    Wizard -> "Wizard"
  }
}

fn character_from_string(s: String) -> Result(Character, Nil) {
  case s {
    "Barbarian" -> Ok(Barbarian)
    "Dwarf" -> Ok(Dwarf)
    "Elf" -> Ok(Elf)
    "Wizard" -> Ok(Wizard)
    _ -> Error(Nil)
  }
}

fn init(_) -> Model {
  get_localstorage("hero")
  |> result.try(model_from_json)
  |> result.unwrap(default_model())
}

fn default_model() -> Model {
  Model(
    name: "Lucy",
    character: Wizard,
    body: 4,
    mind: 8,
    attack_dice: 2,
    defend_dice: 4,
    gold: 100,
    equipment: ["Love"],
  )
}

type Msg {
  UserUpdatedName(String)
  UserUpdatedCharacter(Character)
  UserUpdatedBody(Int)
  UserUpdatedMind(Int)
  UserUpdatedAttackDice(Int)
  UserUpdatedDefendDice(Int)
  UserUpdatedGold(Int)
  UserAddedItem(String)
  UserRemovedItem(Int)
}

fn update(model: Model, msg: Msg) -> Model {
  let model = case msg {
    UserUpdatedName(name) -> Model(..model, name:)
    UserUpdatedCharacter(character) -> Model(..model, character:)
    UserUpdatedBody(body) -> Model(..model, body:)
    UserUpdatedMind(mind) -> Model(..model, mind:)
    UserUpdatedAttackDice(attack_dice) -> Model(..model, attack_dice:)
    UserUpdatedDefendDice(defend_dice) -> Model(..model, defend_dice:)
    UserUpdatedGold(gold) -> Model(..model, gold:)
    UserAddedItem(item) -> Model(..model, equipment: [item, ..model.equipment])
    UserRemovedItem(item_index) ->
      Model(..model, equipment: list_remove_at(model.equipment, item_index))
  }
  set_localstorage("hero", model_to_json(model))

  model
}

fn list_remove_at(list list: List(a), at index: Int) -> List(a) {
  let #(left, right) = list |> list.split(at: index)

  list.append(left, right |> list.drop(1))
}

fn view(model: Model) -> element.Element(Msg) {
  html.div(
    [
      attribute.class(
        "max-w-xl mx-auto p-6 bg-white shadow-md rounded space-y-6",
      ),
    ],
    [
      view_name(model.name),
      view_character(model.character),
      html.hr([attribute.class("border-t border-gray-200")]),
      html.div([attribute.class("grid grid-cols-2 gap-4")], [
        view_int_stat("Body", model.body, 1, UserUpdatedBody),
        view_int_stat("Mind", model.mind, 1, UserUpdatedMind),
        view_int_stat(
          "Attack Dice",
          model.attack_dice,
          1,
          UserUpdatedAttackDice,
        ),
        view_int_stat(
          "Defend Dice",
          model.defend_dice,
          1,
          UserUpdatedDefendDice,
        ),
      ]),
      html.hr([attribute.class("border-t border-gray-200")]),
      view_int_stat("Gold", model.gold, 5, UserUpdatedGold),
      html.hr([attribute.class("border-t border-gray-200")]),
      view_equipment(model.equipment),
    ],
  )
}

fn view_name(name: String) -> element.Element(Msg) {
  html.div([attribute.class("flex flex-col")], [
    html.label([attribute.class("text-md text-gray-700 mb-1")], [
      html.text("Name"),
    ]),
    html.input([
      attribute.type_("text"),
      attribute.value(name),
      event.on_input(UserUpdatedName),
      attribute.class(
        "border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500",
      ),
    ]),
  ])
}

fn view_character(character: Character) -> element.Element(Msg) {
  html.div([attribute.class("flex flex-col")], [
    html.label([attribute.class("text-md text-gray-700 mb-1")], [
      html.text("Character"),
    ]),
    html.select(
      [
        event.on_input(fn(v) {
          case character_from_string(v) {
            Ok(v) -> UserUpdatedCharacter(v)
            Error(_) -> UserUpdatedCharacter(character)
          }
        }),
        attribute.class(
          "border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500",
        ),
      ],
      [Barbarian, Dwarf, Elf, Wizard]
        |> list.map(fn(c) {
          html.option(
            [attribute.selected(c == character)],
            character_to_string(c),
          )
        }),
    ),
  ])
}

fn view_int_stat(name: String, value: Int, step: Int, msg: fn(Int) -> Msg) {
  html.div([attribute.class("flex flex-col w-full")], [
    html.label([attribute.class("text-sm font-medium text-gray-700 mb-1")], [
      html.text(name),
    ]),
    html.div([attribute.class("flex items-center space-x-2")], [
      html.button(
        [
          attribute.class("px-3 py-1 bg-gray-200 rounded hover:bg-gray-300"),
          event.on_click(msg(value - step)),
        ],
        [html.text("-")],
      ),
      html.input([
        attribute.class(
          "flex-grow px-3 py-1 border border-gray-300 rounded w-16 text-center no-spinner",
        ),
        attribute.type_("number"),
        attribute.step(int.to_string(step)),
        attribute.value(int.to_string(value)),
        event.on_input(fn(v) {
          case int.parse(v) {
            Ok(v) -> msg(v)
            Error(_) -> msg(value)
          }
        }),
      ]),
      html.button(
        [
          attribute.class("px-3 py-1 bg-gray-200 rounded hover:bg-gray-300"),
          event.on_click(msg(value + step)),
        ],
        [html.text("+")],
      ),
    ]),
  ])
}

fn view_equipment(equipment: List(String)) -> element.Element(Msg) {
  let on_submit =
    event.on_submit(fn(fields) {
      let assert Ok(item) =
        fields
        |> dict.from_list
        |> dict.get("item")
      clear_item()

      UserAddedItem(item)
    })

  html.form([on_submit], [
    html.div([attribute.class("flex flex-col w-full")], [
      html.label([attribute.class("text-sm font-medium text-gray-700 mb-1")], [
        html.text("Equipment"),
      ]),
      html.div([attribute.class("flex flex-row w-full space-x-2")], [
        html.input([
          attribute.class(
            "w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500",
          ),
          attribute.id("item"),
          attribute.name("item"),
          attribute.required(True),
        ]),
        html.button(
          [
            attribute.class("px-3 py-1 bg-gray-200 rounded hover:bg-gray-300"),
            attribute.type_("submit"),
          ],
          [html.text("Add")],
        ),
      ]),
    ]),
    html.ul(
      [attribute.class("list-disc list-inside mt-4 space-y-1 p-2 rounded")],
      list.index_map(equipment, fn(item, index) {
        html.li([], [
          html.div(
            [
              attribute.class(
                "inline-flex items-center justify-between w-full text-gray-700",
              ),
            ],
            [
              html.span([], [html.text(item)]),
              html.button(
                [
                  attribute.class(
                    "ml-2 px-2 py-1 bg-red-500 text-white rounded hover:bg-red-600",
                  ),
                  attribute.type_("button"),
                  event.on_click(UserRemovedItem(index)),
                ],
                [html.text("Delete")],
              ),
            ],
          ),
        ])
      }),
    ),
  ])
}
