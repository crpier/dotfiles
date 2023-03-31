import { A } from "solid-start";
import Counter from "~/components/Counter";

export default function Home() {
  return (
    <main class="text-center mx-auto flex flex-col items-center justify-center text-white">
      <div class="mb-8 border-2 border-gray-600 px-6 pb-6 text-center">
        <p class="my-4 text-xl font-bold">Pula title</p>
        <img src="https://misc-personal-projects.s3.eu-west-1.amazonaws.com/memecry/13.jpg" style="width:500px;"></img>
        <div class="flex flex-grow-0 flex-row items-center justify-start">
        <A href="." class="my-2 mr-2 font-semibold">
          13 good boi points
        </A>
        <div class="flex-grow"></div>
        <div class="font-semibold">
          25 min ago <span class="font-normal text-gray-300">by</span>{" "}
          <A href="." class="font-bold text-green-300">
            {props.owner}
          </A>
        </div>
      </div>
        </div>
      </div>
    </main>
  );
}
