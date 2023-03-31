import {
  createContext,
  createResource,
  createSignal,
  useContext,
} from "solid-js";

import { ApiError, MemecryClient, OpenAPIConfig } from "~/memecry-backend";

const StoreContext = createContext();
const clientConfig: Partial<OpenAPIConfig> = { BASE: "http://localhost:8000" };
const token = localStorage.getItem("Auth");
if (token) {
  clientConfig.TOKEN = token;
}
const backendClient = new MemecryClient(clientConfig);
const app = backendClient.default;

export function Provider(props: any) {
  const [isLoggedIn, setIsLoggedIn] = createSignal(
    !!localStorage.getItem("Auth")
  );
  const [currentUser, { mutate: mutateCurrentUser, refetch }] = createResource(
    isLoggedIn,
    async () => {
      try {
        const resp = await app.getMeApiV1MeGet();
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) {
          await actions.logOut();
          return undefined;
        }
      }
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
      mutateCurrentUser(undefined);
      backendClient.request.config.TOKEN = undefined;
    },
    uploadPost: async (title: string, file: File) => {
      try {
        const resp = await app.uploadPostApiV1UploadPost({ title, file });
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) {
          await actions.logOut();
          return undefined;
        }
      }
    },
    getTopPosts: async () => {
      try {
        return app.getTopPostsApiV1Get();
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) {
          await actions.logOut();
          return undefined;
        }
      }
    },
    getNewPosts: async () => {
      try {
        return app.showNewestPostsApiV1NewGet();
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) {
          await actions.logOut();
          return undefined;
        }
      }
    },
    getPostComments: async (postId: number) => {
      try {
        return app.getCommentsOnPostApiV1PostPostIdCommentsGet(postId);
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) {
          await actions.logOut();
          return undefined;
        }
      }
    },
    postComment: async (postId: number, content: string, attachment?: File) => {
      try {
        return app.commentOnPostApiV1PostPostIdCommentPost(postId, {
          content,
          attachment,
        });
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) {
          await actions.logOut();
          return undefined;
        }
      }
    },
    postCommentReply: async (
      commentId: number,
      content: string,
      attachment?: File
    ) => {
      try {
        return app.postCommentReplyApiV1CommentCommentIdCommentPost(commentId, {
          content,
          attachment,
        });
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) {
          await actions.logOut();
          return undefined;
        }
      }
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
