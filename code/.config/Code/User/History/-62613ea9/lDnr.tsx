import { BiRegularSearch } from "solid-icons/bi";
import { createSignal, Show, Signal } from "solid-js";
import { A } from "solid-start";
import { Outlet } from "solid-start/islands/server-router";
import { useStore } from "~/store";

export default function Nav() {
  const [store] = useStore();
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
          <Show when={store.currentUser()}
            fallback={ <li
              class="px-4 py-2 leading-none text-sm 
                rounded border border-white text-white
                hover:border-transparent hover:bg-white hover:text-gray-800"
            >
              <button onClick={() => setShowLogin(true)}>Log in</button>
            </li>}
          >
            <li class="mr-4 pr-2 rounded hover:bg-gray-600">
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
              class="mr-4 px-4 py-2 leading-none text-sm 
                bg-blue-500 rounded border border-blue-500 text-white
                hover:border-transparent hover:bg-white hover:text-gray-800"
            >
              <button
                onClick={(e) => {
                  setShowUpload(true);
                }}
              >
                Upload
              </button>
            </li>
            <li
              class="px-4 py-2 leading-none text-sm 
                rounded border border-white text-white
                hover:border-transparent hover:bg-white hover:text-gray-800"
            >
              <button>Log out</button>
            </li>
          </Show>
        </ul>
      </nav>
      <Show when={showUpload()}>
        <div>Upload post here</div>
      </Show>
      <Show when={showLogin()}>
        <div
          class="fixed flex flex-col rounded border bg-gray-700 px-4 pb-4 text-white"
          style="left:35vw;top:20vh;width:30vw"
        >
          <div class="mt-2 flex justify-end">
            <button
              class="w-max rounded border bg-gray-900 px-2 text-right hover:bg-gray-700"
              onClick={() => setShowLogin(false)}
            >
              X
            </button>
          </div>
          <p class="mb-1 text-center text-3xl">Login</p>
          <form id="upload-form">
            <div class="mb-4">
              <label for="username">Username</label>
              <input
                class="w-full rounded border p-1 text-black"
                name="username"
              />
            </div>
            <div class="mb-4">
              <label for="password">Password</label>
              <input
                type="password"
                class="w-full rounded border p-1 text-black"
                name="password"
              />
            </div>
            <div class="m-auto flex flex-col justify-center items-center">
              <button
                type="submit"
                class="m-auto rounded border bg-gray-900 px-2 py-1 text-right hover:bg-gray-700"
              >
                Sign in
              </button>
            </div>
          </form>
        </div>
      </Show>
      <Outlet />
    </>
  );
}