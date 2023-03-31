import Nav from "./Nav";
import {
  Body,
  ErrorBoundary,
  FileRoutes,
  Head,
  Html,
  Meta,
  Routes,
  Scripts,
  Title,
} from "solid-start";

export default function App() {
    return (
                <Nav></Nav>
              <Routes>
                <FileRoutes />
              </Routes>
    )
}