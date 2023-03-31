import { Accessor, createContext, createSignal, Setter } from "solid-js";
import { redirect } from "solid-start";
import { MemecryClient, User } from "./memecry-backend";

const BASE_PATH = "http://127.0.0.1:8000";

export class BackendService {
  private appClient: MemecryClient;
  public getUser: Accessor<User | undefined>;
  public setUser: Setter<User | undefined>;

  constructor() {
    // TODO: check for token in localStorage on startup
    // and set user
    this.appClient = new MemecryClient({
      BASE: BASE_PATH,
      CREDENTIALS: "include",
    });
    [this.getUser, this.setUser] = createSignal();
    setTimeout(() => {
      const access_token = localStorage.getItem("Authorization");
      if (access_token) {
        this.appClient.request.config.TOKEN = access_token;
        this.appClient.request.config.WITH_CREDENTIALS = true;
      }
    });
  }

  public async login(username: string, password: string) {
    const { access_token } = await this.appClient.default.loginApiV1TokenPost({
      username,
      password,
    });

    localStorage.setItem("Authorization", access_token);
    this.appClient.request.config.TOKEN = access_token;
    this.appClient.request.config.WITH_CREDENTIALS = true;
    this.setUser(await this.getOwnUser());
  }

  public async getTopPosts() {
    try {
      return await this.appClient.default.getTopPostsApiV1Get();
    } catch (err) {
      console.log(err);
      return [];
    }
  }

  public async getOwnUser() {
    return this.appClient.default.getMeApiV1MeGet();
  }
}

export default function getBackendService() {
  return new BackendService();
}
