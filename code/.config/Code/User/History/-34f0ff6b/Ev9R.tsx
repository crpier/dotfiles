import Nav from "./Nav";
import { FileRoutes, Routes, Body } from "solid-start";
import { useStore } from "~/store";
import { createSignal } from "solid-js";

export default function App() {
  const [store, setStore] = useStore();
  const [appLoaded, setAppLoaded] = createSignal(false);

  return (
    <Body class="bg-black">
      <Nav></Nav>
      <Routes>
        <FileRoutes />
      </Routes>
    </Body>
  );
}
