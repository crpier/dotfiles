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
      const token = resp.access_token;
      backendClient.request.config.TOKEN = token;
      localStorage.setItem("Auth", token);
      setIsLoggedIn(true);
    },
    logOut: async () => {
      localStorage.removeItem("Auth");
      setIsLoggedIn(false);
      mutateCurrentUser(null);
      backendClient.request.config.TOKEN = undefined;
    },
    uploadPost: (title: string, file: File) => {
      return app.uploadPostApiV1UploadPost({ title, file });
    },
    getTopPosts: () => {
      return app.getTopPostsApiV1Get();
    },
    getNewPosts: () => {
      return app.showNewestPostsApiV1NewGet();
    },
    getPostComments: (postId: number) => {
      return app.getCommentsOnPostApiV1PostPostIdCommentsGet(postId);
    },
    postComment: (postId: number, content: string, attachment?: File) => {
      return app.commentOnPostApiV1PostPostIdCommentPost(postId, {
        content,
        attachment,
      });
    },
    postCommentReply: (
      commentId: number,
      content: string,
      attachment?: File
    ) => {
      return app.postCommentReplyApiV1CommentCommentIdCommentPost(commentId, {
        content,
        attachment,
      });
    },
    likePost: (postId: number) => {
      return app.likePostApiV1PostPostIdLikePut(postId);
    },
    unlikePost: (postId: number) => {
      return app.unlikePostApiV1PostPostIdUnlikePut(postId);
    },
    dislikePost: (postId: number) => {
      return app.dislikePostApiV1PostPostIdDislikePut(postId);
    },
    undislikePost: (postId: number) => {
      return app.undislikePostApiV1PostPostIdUndislikePut(postId);
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
