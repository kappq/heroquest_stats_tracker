import { Ok, Error } from "./gleam.mjs";

export function get_localstorage(key) {
  const json = window.localStorage.getItem(key);

  if (json === null) return new Error(undefined);

  try {
    return new Ok(JSON.parse(json));
  } catch {
    return new Error(undefined);
  }
}

export function set_localstorage(key, json) {
  window.localStorage.setItem(key, json);
}

export function clear_item() {
  const el = document.getElementById("item");

  if (el === null) return;

  el.value = "";
}
