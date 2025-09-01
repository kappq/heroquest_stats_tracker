import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result
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
    equipment: ["Dagger"],
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

fn container_classes() -> String {
  "max-w-2xl mx-auto bg-stone-800 rounded-lg border-2 border-amber-600 shadow-2xl overflow-hidden"
}

fn background_classes() -> String {
  "min-h-screen bg-gradient-to-b from-stone-900 via-stone-800 to-stone-900 p-6"
}

fn header_classes() -> String {
  "bg-gradient-to-r from-amber-700 to-amber-600 p-4 border-b-2 border-amber-500"
}

fn title_classes() -> String {
  "text-3xl font-bold text-stone-900 text-center tracking-wider"
}

fn label_classes() -> String {
  "block text-amber-300 font-semibold text-sm uppercase tracking-wide"
}

fn input_classes() -> String {
  "w-full px-4 py-2 bg-stone-700 border-2 border-stone-600 rounded-md text-amber-50 placeholder-stone-400"
}

fn input_focus_classes() -> String {
  "focus:border-amber-500 focus:ring-2 focus:ring-amber-500/20 focus:outline-none transition-all"
}

fn stat_container_classes() -> String {
  "bg-stone-750 p-4 rounded-lg border border-stone-600"
}

fn button_classes() -> String {
  "w-10 h-10 bg-amber-700 hover:bg-amber-600 text-stone-900 font-bold rounded-full"
}

fn button_animation_classes() -> String {
  "transition-all duration-200 transform hover:scale-110 active:scale-95 shadow-lg"
}

fn stat_input_classes() -> String {
  "w-20 px-3 py-2 bg-stone-800 border-2 border-stone-600 rounded-md text-amber-50 text-center font-bold text-lg"
}

fn equipment_item_classes() -> String {
  "bg-stone-750 border border-stone-600 rounded-lg p-3"
}

fn remove_button_classes() -> String {
  "px-3 py-1 bg-red-700 hover:bg-red-600 text-amber-50 text-sm font-medium rounded"
}

fn view(model: Model) -> element.Element(Msg) {
  html.div([attribute.class(background_classes())], [
    html.div([attribute.class(container_classes())], [
      view_header(),
      view_content(model),
    ]),
  ])
}

fn view_header() -> element.Element(Msg) {
  html.div([attribute.class(header_classes())], [
    html.h1([attribute.class(title_classes())], [
      html.text("HEROQUEST STATS TRACKER"),
    ]),
  ])
}

fn view_content(model: Model) -> element.Element(Msg) {
  html.div([attribute.class("p-6 space-y-6")], [
    view_name(model.name),
    view_character(model.character),
    view_divider(),
    view_stats_grid(model),
    view_divider(),
    view_int_stat("Gold", model.gold, 5, UserUpdatedGold),
    view_divider(),
    view_equipment(model.equipment),
  ])
}

fn view_divider() -> element.Element(Msg) {
  html.hr([attribute.class("border-amber-600/30")])
}

fn view_stats_grid(model: Model) -> element.Element(Msg) {
  html.div([attribute.class("grid grid-cols-1 sm:grid-cols-2 gap-4")], [
    view_int_stat("Body", model.body, 1, UserUpdatedBody),
    view_int_stat("Mind", model.mind, 1, UserUpdatedMind),
    view_int_stat("Attack Dice", model.attack_dice, 1, UserUpdatedAttackDice),
    view_int_stat("Defend Dice", model.defend_dice, 1, UserUpdatedDefendDice),
  ])
}

fn view_name(name: String) -> element.Element(Msg) {
  html.div([attribute.class("space-y-2")], [
    view_label("Hero Name"),
    view_text_input(name, "Enter your hero's name", UserUpdatedName),
  ])
}

fn view_character(character: Character) -> element.Element(Msg) {
  html.div([attribute.class("space-y-2")], [
    view_label("Character Class"),
    view_character_select(character),
  ])
}

fn view_label(text: String) -> element.Element(Msg) {
  html.label([attribute.class(label_classes())], [
    html.text(text),
  ])
}

fn view_text_input(
  value: String,
  placeholder: String,
  on_input: fn(String) -> Msg,
) -> element.Element(Msg) {
  html.input([
    attribute.type_("text"),
    attribute.value(value),
    attribute.class(input_classes()),
    attribute.class(input_focus_classes()),
    attribute.placeholder(placeholder),
    event.on_input(on_input),
  ])
}

fn view_character_select(character: Character) -> element.Element(Msg) {
  html.select(
    [
      attribute.class(input_classes()),
      attribute.class(input_focus_classes()),
      attribute.class("cursor-pointer"),
      event.on_input(fn(v) {
        case character_from_string(v) {
          Ok(v) -> UserUpdatedCharacter(v)
          Error(_) -> UserUpdatedCharacter(character)
        }
      }),
    ],
    view_character_options(character),
  )
}

fn view_character_options(selected: Character) -> List(element.Element(Msg)) {
  list.map([Barbarian, Dwarf, Elf, Wizard], fn(c) {
    html.option([attribute.selected(c == selected)], character_to_string(c))
  })
}

fn view_int_stat(name: String, value: Int, step: Int, msg: fn(Int) -> Msg) {
  html.div([attribute.class(stat_container_classes())], [
    view_stat_label(name),
    view_stat_controls(value, step, msg),
  ])
}

fn view_stat_label(name: String) -> element.Element(Msg) {
  html.label([attribute.class(label_classes()), attribute.class("mb-3")], [
    html.text(name),
  ])
}

fn view_stat_controls(
  value: Int,
  step: Int,
  msg: fn(Int) -> Msg,
) -> element.Element(Msg) {
  html.div([attribute.class("flex items-center justify-center space-x-3")], [
    view_stat_button("-", msg(value - step)),
    view_stat_input(value, step, msg),
    view_stat_button("+", msg(value + step)),
  ])
}

fn view_stat_button(text: String, on_click: Msg) -> element.Element(Msg) {
  html.button(
    [
      attribute.class(button_classes()),
      attribute.class(button_animation_classes()),
      event.on_click(on_click),
    ],
    [html.text(text)],
  )
}

fn view_stat_input(
  value: Int,
  step: Int,
  msg: fn(Int) -> Msg,
) -> element.Element(Msg) {
  html.input([
    attribute.type_("number"),
    attribute.step(int.to_string(step)),
    attribute.value(int.to_string(value)),
    attribute.class(stat_input_classes()),
    attribute.class(
      "focus:border-amber-500 focus:ring-2 focus:ring-amber-500/20 focus:outline-none",
    ),
    event.on_input(fn(v) {
      case int.parse(v) {
        Ok(v) -> msg(v)
        Error(_) -> msg(value)
      }
    }),
  ])
}

fn view_equipment(equipment: List(String)) -> element.Element(Msg) {
  html.form([attribute.class("space-y-4"), view_equipment_submit_handler()], [
    view_equipment_input(),
    view_equipment_list(equipment),
  ])
}

fn view_equipment_submit_handler() {
  event.on_submit(fn(fields) {
    let assert Ok(item) =
      fields
      |> dict.from_list
      |> dict.get("item")
    clear_item()
    UserAddedItem(item)
  })
}

fn view_equipment_input() -> element.Element(Msg) {
  html.div([attribute.class("space-y-2")], [
    view_label("Equipment & Items"),
    view_equipment_add_form(),
  ])
}

fn view_equipment_add_form() -> element.Element(Msg) {
  html.div([attribute.class("flex space-x-3")], [
    view_equipment_text_input(),
    view_equipment_add_button(),
  ])
}

fn view_equipment_text_input() -> element.Element(Msg) {
  html.input([
    attribute.id("item"),
    attribute.name("item"),
    attribute.required(True),
    attribute.class("flex-1"),
    attribute.class(input_classes()),
    attribute.class(input_focus_classes()),
    attribute.placeholder("Enter equipment name"),
  ])
}

fn view_equipment_add_button() -> element.Element(Msg) {
  html.button(
    [
      attribute.type_("submit"),
      attribute.class(
        "px-6 py-2 bg-amber-700 hover:bg-amber-600 text-stone-900 font-semibold rounded-md",
      ),
      attribute.class(
        "transition-all duration-200 transform hover:scale-105 active:scale-95 shadow-lg",
      ),
    ],
    [html.text("Add")],
  )
}

fn view_equipment_list(equipment: List(String)) -> element.Element(Msg) {
  case equipment {
    [] -> view_empty_equipment()
    _ -> view_equipment_items(equipment)
  }
}

fn view_empty_equipment() -> element.Element(Msg) {
  html.div([attribute.class("text-stone-400 text-center py-8 italic")], [
    html.text("No equipment yet. Add some gear to your inventory!"),
  ])
}

fn view_equipment_items(equipment: List(String)) -> element.Element(Msg) {
  html.ul(
    [attribute.class("space-y-2 mt-4")],
    list.index_map(equipment, view_equipment_item),
  )
}

fn view_equipment_item(item: String, index: Int) -> element.Element(Msg) {
  html.li([attribute.class(equipment_item_classes())], [
    view_equipment_item_content(item, index),
  ])
}

fn view_equipment_item_content(item: String, index: Int) -> element.Element(Msg) {
  html.div([attribute.class("flex items-center justify-between")], [
    view_equipment_item_name(item),
    view_equipment_remove_button(index),
  ])
}

fn view_equipment_item_name(item: String) -> element.Element(Msg) {
  html.span([attribute.class("text-amber-50 font-medium flex items-center")], [
    view_equipment_bullet(),
    html.text(item),
  ])
}

fn view_equipment_bullet() -> element.Element(Msg) {
  html.span([attribute.class("w-2 h-2 bg-amber-500 rounded-full mr-3")], [])
}

fn view_equipment_remove_button(index: Int) -> element.Element(Msg) {
  html.button(
    [
      attribute.type_("button"),
      attribute.class(remove_button_classes()),
      attribute.class(
        "transition-all duration-200 transform hover:scale-105 active:scale-95",
      ),
      event.on_click(UserRemovedItem(index)),
    ],
    [html.text("Remove")],
  )
}
