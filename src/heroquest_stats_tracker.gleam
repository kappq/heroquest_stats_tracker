import gleam/int
import gleam/list
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event

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
  )
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
  Model(
    name: "Lucy",
    character: Elf,
    body: 6,
    mind: 8,
    attack_dice: 2,
    defend_dice: 1,
    gold: 0,
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
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserUpdatedName(name) -> Model(..model, name:)
    UserUpdatedCharacter(character) -> Model(..model, character:)
    UserUpdatedBody(body) -> Model(..model, body:)
    UserUpdatedMind(mind) -> Model(..model, mind:)
    UserUpdatedAttackDice(attack_dice) -> Model(..model, attack_dice:)
    UserUpdatedDefendDice(defend_dice) -> Model(..model, defend_dice:)
    UserUpdatedGold(gold) -> Model(..model, gold:)
  }
}

fn view(model: Model) -> element.Element(Msg) {
  html.div([], [
    view_name(model.name),
    view_character(model.character),
    view_int_stat("Body", model.body, 1, UserUpdatedBody),
    view_int_stat("Mind", model.mind, 1, UserUpdatedMind),
    view_int_stat("Attack Dice", model.attack_dice, 1, UserUpdatedAttackDice),
    view_int_stat("Defend Dice", model.defend_dice, 1, UserUpdatedDefendDice),
    view_int_stat("Gold", model.gold, 5, UserUpdatedGold),
  ])
}

fn view_name(name: String) -> element.Element(Msg) {
  html.div([], [
    html.label([], [html.text("Name: ")]),
    html.input([
      attribute.type_("text"),
      attribute.value(name),
      event.on_input(UserUpdatedName),
    ]),
  ])
}

fn view_character(character: Character) -> element.Element(Msg) {
  html.div([], [
    html.label([], [html.text("Character: ")]),
    html.select(
      [
        event.on_input(fn(v) {
          case character_from_string(v) {
            Ok(v) -> UserUpdatedCharacter(v)
            Error(_) -> UserUpdatedCharacter(character)
          }
        }),
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
  html.div([], [
    html.label([], [html.text(name <> ": ")]),
    html.input([
      attribute.type_("number"),
      attribute.value(int.to_string(value)),
      attribute.step(int.to_string(step)),
      event.on_input(fn(v) {
        case int.parse(v) {
          Ok(v) -> msg(v)
          Error(_) -> msg(value)
        }
      }),
    ]),
  ])
}
