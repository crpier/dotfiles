import getBackendService from "~/services";
import { useService } from "solid-services";

export default function Login() {
  const backendService = useService(getBackendService);

  const logIn = (e: SubmitEvent) => {
    e.preventDefault();
    const form: HTMLFormElement = e.target;
    const username = form.elements[0].value;
    const password = form.elements[1].value;
  };

  return (
    <div
      class="fixed flex flex-col rounded border bg-gray-700 px-4 pb-4 text-white"
      style="left:35vw;top:20vh;width:30vw"
    >
      <div class="mt-2 flex justify-end">
        <button class="w-max rounded border bg-gray-900 px-2 text-right hover:bg-gray-700">
          X
        </button>
      </div>
      <p class="mb-1 text-center text-3xl">Login</p>
      <form id="upload-form" onSubmit={logIn}>
        <div class="mb-4">
          <label for="username">Username</label>
          <input class="w-full rounded border p-1" name="username" />
        </div>
        <div class="mb-4">
          <label for="password">Password</label>
          <input
            type="password"
            class="w-full rounded border p-1"
            name="password"
          />
        </div>
        <div class="m-auto flex flex-col justify-center items-center">
          <button
            type="submit"
            class="m-auto rounded border border bg-gray-900 px-2 py-1 text-right hover:bg-gray-700"
          >
            Sign in
          </button>
        </div>
      </form>
    </div>
  );
}
