import Nav from "./Nav";
import { FileRoutes, Routes, Body } from "solid-start";
import { useStore } from "~/store";

export default function App() {
  return (
    <Body class="bg-black">
      <Nav></Nav>
      <Routes>
        <FileRoutes />
      </Routes>
    </Body>
  );
}
