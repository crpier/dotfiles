import { Accessor, createContext, createSignal, Setter } from "solid-js";
import { redirect } from "solid-start";
import { MemecryClient, User } from "./memecry-backend";

const BASE_PATH = "http://127.0.0.1:8000";
const BackendContext = createContext();

export default class BackendService {
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
 }

  public async login(username: string, password: string) {
    const { access_token } = await this.appClient.default.loginApiV1TokenPost({
      username,
      password,
    });

    localStorage.setItem("Authorization", access_token);
    this.appClient.request.config.TOKEN = access_token;
    this.setUser(await this.getOwnUser());
  }

  public async getTopPosts() {
    try {
    return this.appClient.default.getTopPostsApiV1Get();
    } catch (err) {
      console.log(err);
    }
  }

  public async getOwnUser() {
    return this.appClient.default.getMeApiV1MeGet();
  }
}
