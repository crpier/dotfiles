import Nav from "./Nav";
import { FileRoutes, Routes } from "solid-start";

export default function App() {
  return (
    <>
      <Nav></Nav>
      <Routes>
        <FileRoutes />
      </Routes>
    </>
  );
}
