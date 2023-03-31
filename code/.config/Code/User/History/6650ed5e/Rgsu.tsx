import { BiRegularSearch } from 'solid-icons/bi'

// @refresh reload
import { Suspense } from "solid-js";
import {
  useLocation,
  A,
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

export default function Root() {
  const location = useLocation();
  return (
    <Html lang="en">
      <Head>
        <Title>SolidStart - With TailwindCSS</Title>
        <Meta charset="utf-8" />
        <Meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>
      <Body>
        <Suspense>
          <ErrorBoundary>
            <nav class="bg-gray-800 font-semibold">
              <ul class="flex items-center p-3 text-gray-200">
                <li class="mr-8">
                  <A href="/" class="text-xl font-bold tracking-tight">Memecry</A>
                </li>
                <li class={"mr-2"}>
                  <A href="/latest">Latest</A>
                </li>
                <div class="md:flex-grow"></div>
                <li class="flex flex-row">
                  <img src="https://misc-personal-projects.s3.eu-west-1.amazonaws.com/memecry/13.jpg"
                   alt="profile picture of user"
                   class="mr-2"
                   style="width:2rem;height:2rem">

                  </img>
                </li>
                <li class="mr-4 flex justify-center items-center">
                  <button>
                    <BiRegularSearch size={"2em"} color="white"></BiRegularSearch>
                  </button>
                </li>
                <li class="mr-4 px-4 py-2 leading-none text-sm 
                bg-blue-500 rounded border border-blue-500 text-white
                hover:border-transparent hover:bg-white hover:text-gray-800">
                  <button>Upload</button>
                </li>
                <li class="px-4 py-2 leading-none text-sm 
                rounded border border-white text-white
                hover:border-transparent hover:bg-white hover:text-gray-800">
                  <button>Log in</button>
                </li>
              </ul>
            </nav>
            <Routes>
              <FileRoutes />
            </Routes>
          </ErrorBoundary>
        </Suspense>
        <Scripts />
      </Body>
    </Html>
  );
}
