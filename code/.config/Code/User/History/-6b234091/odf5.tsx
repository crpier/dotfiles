// @refresh reload
import { Suspense } from "solid-js";
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
import "./root.css";
import { ServiceRegistry, useService } from "solid-services";
import Nav from "./components/Nav";
import BackendService from "./services";

export default function Root() {

const backendService = useService(() => new BackendService());
  return (
    <Html lang="en">
      <Head>
        <Title>SolidStart - With TailwindCSS</Title>
        <Meta charset="utf-8" />
        <Meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>
      <Body class="bg-black">
        <Suspense>
          <ErrorBoundary>
            <ServiceRegistry>
              <Nav backendService={backendService}></Nav>
              <Routes>
                <FileRoutes />
              </Routes>
            </ServiceRegistry>
          </ErrorBoundary>
        </Suspense>
        <Scripts />
      </Body>
    </Html>
  );
}
