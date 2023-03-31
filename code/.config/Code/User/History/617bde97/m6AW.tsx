import { BiRegularSearch } from "solid-icons/bi";
import { createSignal, Show, Signal } from "solid-js";
import { A } from "solid-start";
import { useStore } from "~/store";
import Login from "./Login";
import PostUploadForm from "./Upload";

export default function Nav() {
  const [store, storeActions] = useStore();

  const [showUpload, setShowUpload] = createSignal(false);
  const [showLogin, setShowLogin] = createSignal(false);

  return (
    <>
      <nav class="bg-gray-800 font-semibold">
        <ul class="flex items-center px-4 py-2 text-gray-200">
          <li class="mr-8">
            <A
              href="/"
              class="text-xl font-bold tracking-tight hover:text-gray-400"
            >
              Memecry
            </A>
          </li>
          <li class={"mr-2 hover:text-gray-400"}>
            <A href="/latest">Latest</A>
          </li>
          <div class="md:flex-grow"></div>
          <li class="mr-4 flex justify-center items-center rounded text-white hover:text-gray-300">
            <button>
              <BiRegularSearch size={"2em"}></BiRegularSearch>
            </button>
          </li>
          <Show
            fallback={
              <li
                class="leading-none text-sm 
                rounded border border-white text-white
                hover:border-transparent hover:bg-white hover:text-gray-800"
              >
                <button class="px-4 py-2" onClick={() => setShowLogin(true)}>
                  Log in
                </button>
              </li>
            }
            when={store.currentUser()}
          >
            <li class="leading-7 mr-4 pr-2 rounded hover:bg-gray-600">
              <A href="/" class="flex flex-row">
                <img
                  src="https://misc-personal-projects.s3.eu-west-1.amazonaws.com/memecry/13.jpg"
                  alt="profile picture of user"
                  class="mr-2 rounded"
                  style="width:2rem;height:2rem"
                ></img>
                <span>cris</span>
              </A>
            </li>
            <li
              class="mr-4 leading-none text-sm 
                bg-blue-500 rounded border border-blue-500 text-white
                hover:border-transparent hover:bg-white hover:text-gray-800"
            >
              <button
                class="px-4 py-2"
                onClick={(e) => {
                  setShowUpload(true);
                }}
              >
                Upload
              </button>
            </li>
            <li
              class="leading-none text-sm 
                rounded border border-white text-white
                hover:border-transparent hover:bg-white hover:text-gray-800"
            >
              <button class="px-4 py-2" onClick={storeActions.logOut}>
                Log out
              </button>
            </li>
          </Show>
        </ul>
      </nav>
      <Show when={showUpload()}>
        <PostUploadForm
          hideUpload={() => setShowUpload(false)}
          uploadPost={storeActions.uploadPost}
        />
      </Show>
      <Show when={showLogin()}>
        <Login
          hideLogin={() => setShowLogin(false)}
          logIn={(username: string, password: string) =>
            storeActions.logIn(username, password)
          }
        ></Login>
      </Show>
    </>
  );
}
