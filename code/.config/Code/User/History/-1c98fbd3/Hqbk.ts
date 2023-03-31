import { createContext, useContext } from "solid-js";
import { createStore } from "solid-js/store";

const StoreContext = createContext();

export function Provider(props) {
    [state, setState] = createStore({
        get posts() {return []}
    })
}