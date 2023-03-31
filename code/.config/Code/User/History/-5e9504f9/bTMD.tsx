import { BsChatLeft } from "solid-icons/bs";
import { ImArrowDown, ImArrowUp } from "solid-icons/im";
import { For } from "solid-js";
import { A } from "solid-start";
import { Post } from "~/memecry-backend";

export default function Posts(props: { posts: Post[] | undefined }) {
  return (
    <For each={props.posts}>
      {(post, i) => (
        <main class="text-center mx-auto flex flex-col items-center justify-center text-white">
          <div class="mt-8 border-2 border-gray-600 px-6 pb-6 text-center bg-[#101010]">
            <A href=".">
              <p class="my-4 text-xl font-bold">{post.title}</p>
              <img
                src="https://misc-personal-projects.s3.eu-west-1.amazonaws.com/memecry/13.jpg"
                style="width:500px;"
              ></img>
            </A>
            <div class="flex flex-grow-0 flex-row items-center justify-start">
              <div class="my-2 mr-2 font-semibold">13 good boi points</div>
              <div class="flex-grow"></div>
              <div class="font-semibold">
                25 min ago <span class="font-normal text-gray-300">by</span>{" "}
                <A href="." class="font-bold text-green-300">
                  cristi
                </A>
              </div>
            </div>
            <div class="flex flex-grow-0 flex-row items-center justify-start">
              <button class="mr-2 rounded-md border border-gray-600 p-2 hover:border-gray-500">
                <ImArrowUp size={"1rem"} />
              </button>
              <button class="rounded-md border border-gray-600 p-2 hover:border-gray-500">
                <ImArrowDown size={"1rem"} />
              </button>
              <div class="flex-grow"></div>
              <A
                href="."
                class="flex flex-row rounded-md border border-gray-600 p-2 hover:border-gray-500"
              >
                <BsChatLeft size={"1rem"} class="mt-1.5 mr-2" />
                <div>420 comments</div>
              </A>
            </div>
          </div>
        </main>
      )}
    </For>
  );
}
