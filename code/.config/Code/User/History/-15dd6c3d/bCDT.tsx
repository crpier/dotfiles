import { createSignal, Show } from "solid-js";

export default function PostUploadForm(props: {
  hideUpload: () => void;
  uploadPost: (title: string, file: File) => any;
}) {
  const [fileUpload, setFileUpload] = createSignal<File | null>();
  const [createObjectURL, setCreateObjectURL] = createSignal("");

  const uploadToClient = (event: { target: HTMLInputElement }) => {
    const target = event.target;
    const targetFiles = target.files as FileList;
    const targetFile = targetFiles[0];
    if (targetFile) {
      const f = targetFile;
      const url = URL.createObjectURL(f);
      setFileUpload(f);
      setCreateObjectURL(url);
    }
  };

  const uploadToServer = (event) => {
    const title = document.getElementById("post-id")?.value;
    props.uploadPost(title, fileUpload());
  };

  function cancelUpload() {
    setFileUpload(null);
    setCreateObjectURL("");
  }
  return (
    <div
      class="absolute flex flex-col rounded border bg-gray-700 px-4 pb-4 text-white"
      style={{ left: "30vw", top: "5vh", width: "40vw" }}
    >
      <div class="mt-2 flex justify-end">
        <button
          class="w-max rounded border border bg-gray-900 px-2 text-right hover:bg-gray-700"
          onClick={() => props.hideUpload()}
        >
          X
        </button>
      </div>
      <p class="mb-1 text-center text-3xl">Upload post</p>
      <div class="mb-4">
        <label class="" for="post-title">
          Title
        </label>
        <input class="text-black w-full rounded border p-1" id="post-title" />
      </div>
      <Show
        fallback={
          <div class="flex h-96 flex-col items-center rounded border border-dashed bg-gray-900 p-6 text-center">
            <label class="mb-4">Upload file up to 10mb</label>
            <input class="w-max" type="file" onChange={uploadToClient} />
          </div>
        }
        when={createObjectURL()}
      >
        <img src={createObjectURL()}></img>
      </Show>
      <div class="flex flex-row justify-start">
        <button
          class="mt-4 rounded border border-white px-4 py-1 text-sm font-semibold hover:border-transparent hover:bg-white hover:text-teal-500"
          onclick={cancelUpload}
        >
          Cancel
        </button>
        <button
          class="mt-4 ml-4 rounded border-white bg-blue-500 px-4 py-1 text-sm font-semibold hover:border-transparent hover:bg-white hover:text-teal-500"
          onclick={uploadToServer}
        >
          Submit
        </button>
      </div>
    </div>
  );
}
