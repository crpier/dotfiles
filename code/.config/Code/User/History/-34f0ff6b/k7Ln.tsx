import Nav from "./Nav";
import { FileRoutes, Routes, Body } from "solid-start";
import { useStore } from "~/store";
import { createSignal } from "solid-js";

export default function App() {
  const [store, { pullUser }] = useStore();
  const [appLoaded, setAppLoaded] = createSignal(false);

  return (
    <>
      <Nav></Nav>
      <Routes>
        <FileRoutes />
      </Routes>
    </>
  );
}
