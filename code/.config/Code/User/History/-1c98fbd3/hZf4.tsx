import {
  createContext,
  createResource,
  createSignal,
  useContext,
} from "solid-js";

const StoreContext = createContext();

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
      const resp = await request_send("post", "/token", {
        username,
        password,
        grant_type: "password",
      });
      const token = resp?.access_token;
      localStorage.setItem("Auth", token);
      setIsLoggedIn(true);
    },
    logOut: async () => {
      localStorage.removeItem("Auth");
      setIsLoggedIn(false);
      mutateCurrentUser(null);
    },
    uploadPost: (title: string, file: File) => {
      console.log(title);
      console.log(file);
      return request_send("post", "/api/v1/upload", { title, file });
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
