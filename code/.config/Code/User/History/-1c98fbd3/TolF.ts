import { createContext, useContext } from "solid-js";
import { createStore } from "solid-js/store";

const StoreContext = createContext();

export function Provider(props) {
  const [state, setState] = createStore({
    get posts() {
      return [];
    },
    get comments() {
      return [];
    },
    page: 0,
    token: localStorage.getItem("Authentication"),
  });
  const actions = {};
  const store = [state, actions];

  return (
    <StoreContext.Provider value={store}>{props.children}</StoreContext>
  )
}
