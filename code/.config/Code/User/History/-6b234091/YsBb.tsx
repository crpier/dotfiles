// @refresh reload
import { ErrorBoundary, Head, Html, Meta, Scripts, Title } from "solid-start";
import "./root.css";
import { Provider } from "./store";
import Nav from "./components/Nav";
import { FileRoutes, Routes, Body } from "solid-start";

export default function Root() {
  return (
    <Html lang="en">
      <Head>
        <Title>SolidStart - With TailwindCSS</Title>
        <Meta charset="utf-8" />
        <Meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>
      <Provider>
        <Body class="bg-black">
          <Routes>
            <FileRoutes />
          </Routes>
        </Body>
      </Provider>
      <Scripts />
    </Html>
  );
}
