import { BiRegularSearch } from "solid-icons/bi";
import { createSignal, Show, Signal } from "solid-js";
import { A } from "solid-start";
import { useStore } from "~/store";
import Login from "./Login";

export default function Nav() {
  const [store, storeActions] = useStore();

  const [showUpload, setShowUpload] = createSignal(false);
  const [showLogin, setShowLogin] = createSignal(true);

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
          <Show when={store.currentUser()}>
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
          <Show when={!store.currentUser()}>
            <li
              class="px-4 py-2 leading-none text-sm 
                rounded border border-white text-white
                hover:border-transparent hover:bg-white hover:text-gray-800"
            >
              <button onClick={() => setShowLogin(true)}>Log in</button>
            </li>
          </Show>
        </ul>
      </nav>
      <Show when={showUpload()}>
        <div
          class="absolute flex flex-col rounded border bg-gray-700 px-4 pb-4 text-white"
          style={{ left: "30vw", top: "5vh", width: "40vw" }}
        >
          <div class="mt-2 flex justify-end">
            <button
              class="w-max rounded border border bg-gray-900 px-2 text-right hover:bg-gray-700"
              onClick={() => setShowUpload(false)}
            >
              X
            </button>
          </div>
          <p class="mb-1 text-center text-3xl">Upload post</p>
          <div class="mb-4">
            <label class="">Title</label>
            <input class="w-full rounded border p-1" />
          </div>
          <div class="flex h-64 flex-col items-center rounded border border-dashed bg-gray-900 p-6 text-center">
            <label class="mb-4">Upload file up to 10mb</label>
            <input class="w-max" type="file" placeholder="lolaw" />
          </div>
          <div class="flex flex-row justify-start">
            <button class="mt-4 rounded border border-white px-4 py-1 text-sm font-semibold hover:border-transparent hover:bg-white hover:text-teal-500">
              Cancel
            </button>
            <button class="mt-4 ml-4 rounded border-white bg-blue-500 px-4 py-1 text-sm font-semibold hover:border-transparent hover:bg-white hover:text-teal-500">
              Submit
            </button>
          </div>
        </div>
        ,
      </Show>
      <Show when={showLogin()}>
        <Login hideLogin={() => setShowLogin(false)}
         logIn={(username ; str) => storeActions.logIn(username, password)}
        }></Login>
      </Show>
    </>
  );
}
