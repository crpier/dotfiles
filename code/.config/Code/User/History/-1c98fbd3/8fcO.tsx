import {
  createContext,
  createResource,
  createSignal,
  useContext,
} from "solid-js";

import { MemecryClient, OpenAPIConfig } from "~/memecry-backend";

const StoreContext = createContext();
const clientConfig: Partial<OpenAPIConfig> = { BASE: "http://localhost:8000" };
const token = localStorage.getItem("Auth");
if (token) {
  clientConfig.TOKEN = token;
}
const backendClient = new MemecryClient(clientConfig);
const app = backendClient.default;

async function request_send(
  method: string,
  url: string,
  formData?: any,
  body?: any
) {
  const headers: any = {};
  const opts: any = { method, headers };

  const token = localStorage.getItem("Auth");
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  if (formData) {
    let formReq = new FormData();
    for (const entry in formData) {
      formReq.append(entry, formData[entry]);
    }
    opts.body = formReq;
  }

  if (body) {
    headers["Content-Type"] = "multipart/form-data";
    opts.body = body;
  }
  const response = await fetch(`http://localhost:8000${url}`, opts);
  return response.json();
}

export function Provider(props: any) {
  const [isLoggedIn, setIsLoggedIn] = createSignal(
    !!localStorage.getItem("Auth")
  );
  const [currentUser, { mutate: mutateCurrentUser, refetch }] = createResource(
    isLoggedIn,
    async () => {
      return request_send("get", "/api/v1/me");
    }
  );

  const state = {
    currentUser,
    isLoggedIn,
  };
  const actions = {
    logIn: async (username: string, password: string) => {
      const resp = await app.loginApiV1TokenPost({ username, password });
      console.log(resp);
      const token = resp.access_token;
      backendClient.request.config.TOKEN = token;
      localStorage.setItem("Auth", token);
      setIsLoggedIn(true);
    },
    logOut: async () => {
      localStorage.removeItem("Auth");
      setIsLoggedIn(false);
      mutateCurrentUser(null);
    },
    uploadPost: (title: string, file: File) => {
      return request_send("post", "/api/v1/upload", { title, file });
    },
    getTopPosts: () => {
      return request_send("get", "/api/v1/");
    },
  };
  const store = [state, actions];
  return (
    <StoreContext.Provider value={store}>
      {props.children}
    </StoreContext.Provider>
  );
}

export function useStore(): any {
  return useContext(StoreContext);
}