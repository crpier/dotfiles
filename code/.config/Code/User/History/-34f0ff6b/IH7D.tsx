import Nav from "./Nav";
import { FileRoutes, Routes, Body } from "solid-start";

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
