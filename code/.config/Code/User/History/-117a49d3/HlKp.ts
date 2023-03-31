import { Accessor, createContext, createSignal, Setter } from "solid-js";
import { redirect } from "solid-start";
import { MemecryClient, User } from "./memecry-backend";

const BASE_PATH = "http://127.0.0.1:8000";
const BackendContext = createContext();

export default function BackendService() {
  // TODO: check for token in localStorage on startup
  // and set user
  const appClient = new MemecryClient({
    BASE: BASE_PATH,
    CREDENTIALS: "include",
  });
  const [getUser, setUser] = createSignal();

  return {
    async login(username: string, password: string) {
      const { access_token } = await appClient.default.loginApiV1TokenPost({
        username,
        password,
      });

      localStorage.setItem("Authorization", access_token);
      appClient.request.config.TOKEN = access_token;
      setUser(await getOwnUser());
    },

    getTopPosts() {
      return appClient.default.getTopPostsApiV1Get();
    },

    getOwnUser() {
      return appClient.default.getMeApiV1MeGet();
    },
  };
}
