export default function PostUploadForm(props: { hideUpload: () => void }) {
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
  );
}
