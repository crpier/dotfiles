// @refresh reload
import {
  ErrorBoundary,
  Head,
  Html,
  Meta,
  Scripts,
  Title,
} from "solid-start";
import "./root.css";
import App from "./components/App";
import { Provider } from "./store";

export default function Root() {
  return (
    <Html lang="en">
      <Head>
        <Title>SolidStart - With TailwindCSS</Title>
        <Meta charset="utf-8" />
        <Meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>
        <Provider>
          <App></App>
        </Provider>
      <Scripts />
    </Html>
  );
}
