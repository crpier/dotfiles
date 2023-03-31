// @refresh reload
import { Head, Html, Meta, Title } from "solid-start";
import App from "./components/App";
import "./root.css";
import { Provider } from "./store";
import Nav from "./components/Nav";
import { FileRoutes, Routes, Body } from "solid-start";
import { ErrorBoundary } from "solid-js";

export default function Root() {
  return (
    <Html lang="en">
      <Head>
        <Title>Memecry</Title>
        <Meta charset="utf-8" />
        <Meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>
      <Body class="bg-black">
        <ErrorBoundary>
          <Provider>
            <Nav></Nav>
            <Routes>
              <FileRoutes />
            </Routes>
          </Provider>
        </ErrorBoundary>
      </Body>
    </Html>
  );
}
