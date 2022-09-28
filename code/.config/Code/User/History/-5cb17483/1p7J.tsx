import { create } from "domain";
import { writeSync } from "fs";
import type { NextPage } from "next";
import Head from "next/head";
import { useEffect, useState, Component } from "react";
import internal from "stream";
import { writeHeapSnapshot } from "v8";

type Loc = {
  row: number
  col: number
}

type thingStyle = {
  height: number
  width: number
  position: "absolute"
  zIndex: number
  marginLeft?: number
  marginTop?: number
}

type thingData = {
  sprite: string
  style: thingStyle
}

const type_to_props = new Map<string, thingData>([
  ["Grass", { sprite: "grass.png", style: { height: 96, width: 96, position: "absolute", zIndex: 0 } }],
  ["House", { sprite: "house.png", style: { height: 48, width: 48, position: "absolute", zIndex: 1, marginLeft: 10, marginTop: 20 } }],
  ["Champion", { sprite: "champion.png", style: { height: 48, width: 48, position: "absolute", zIndex: 1, marginLeft: 10, marginTop: 20 } }],
  ["Barrack", { sprite: "barrack.png", style: { height: 72, width: 72, position: "absolute", zIndex: 1, marginLeft: 12, marginTop: 12 } }],
  ["Tower", { sprite: "tower.png", style: { height: 72, width: 72, marginLeft: 12, marginTop: 12, position: "absolute", zIndex: 1 } }],
  ["Soldier", { sprite: "soldier.png", style: { height: 48, width: 48, position: "absolute", zIndex: 1, marginLeft: 10, marginTop: 20 } }],
])

function Thing(props: { left: number, top: number, type: string, ws: WebSocket, openPopup: (e: any) => any }) {
  // TODO: this should be a map really
  let style = { ...type_to_props.get(props.type).style }
  style.left = 48 + props.left * 96
  style.top = 48 + props.top * 96

  return (<img src={type_to_props.get(props.type).sprite} style={style} />);
}

class World extends Component {
  // @ts-ignore
  ws: WebSocket = {}
  constructor(props: any) {
    super(props)
    this.state = { items: [], popup: {} }
    const worldHeight = 20
    const worldWidth = 20
  }
  componentDidMount() {
    this.ws = new WebSocket("ws://localhost:8000")
    this.ws.onopen = (event: any) => {
      // is this a workaround or proper react etiquette?
      setTimeout(() => (
        this.ws.send(JSON.stringify({ type: "event", event: "connection", data: "some string or smth" }))
      ), 100)
    }
    this.ws.onmessage = (message: any) => {
      let data = JSON.parse(message.data)
      if (data.type == "info") {
        this.setState({ items: data.data })
      }
      console.log(this.state)
    }
  }

  componentWillUnmount(): void {
    this.ws.close(1000)
  }

  openPopup = (e: any) => {
    this.setState(
      {
        popup:
        {
          target:
            { type: "House", top: 1, left: 0 },
          popup: { left: 2, top: 1 },
        },
      }
    )
  }

  closePopup = (e: any) => {
    console.log("tried to close poopup")
    this.setState({ popup: {} })
  }

  render() {
    return <main className="container mx-auto flex flex-col items-center justify-center min-h-screen p-4">
      {this.state.popup.target && <Popup target={this.state.popup.target} popup={this.state.popup.popup} ws={this.ws} closeHandler={this.closePopup}></Popup>}
      {/* @ts-ignore */}
      {this.state.items?.map((item: any) => (
        <div onClick={this.openPopup}>
          <Thing type={item.type} left={item.loc.col} top={item.loc.row} key={`${item.type}:${item.loc.row}-${item.loc.col}`} ws={this.ws} openPopup={this.openPopup} />
        </div>
      ))}
    </main>
  }
}

function Popup(props: { target: { type: string, left: number, top: number }, popup: { left: number, top: number }, ws: WebSocket, closeHandler: (e: any) => void }) {

  function createThing(e) {
    const eventType = props.target.type == "Grass" ? "delete" : "create"
    console.log({ type: props.target.type, col: props.target.left, row: props.target.top })
    const notification = JSON.stringify({
      type: "event",
      event: eventType,
      data: JSON.stringify({ type: props.target.type, col: props.target.left, row: props.target.top })
    })
    props.ws.send(notification)
    props.closeHandler({})
  }

  return <div style={{ position: "absolute", top: 96, left: 96, zIndex: 100 }} className="p-2 bg-yellow-500">
    <p>Create Thing</p>
    <ul>
      <li onClick={createThing} className="flex p-1 my-4 hover:bg-yellow-300"><p className="flex-grow">House</p><img className="mx-4" src="house.png"></img></li>
      <li className="flex p-1 my-4 hover:bg-yellow-300"><p className="flex-grow">Barrack</p><img className="mx-4" src="barrack.png"></img></li>
      <li className="flex p-1 my-4 hover:bg-yellow-300"><p className="flex-grow">Tower</p><img className="mx-4" src="tower.png"></img></li>
      <li className="flex p-1 my-4 hover:bg-yellow-300"><p className="flex-grow">Soldier</p><img className="mx-4" src="soldier.png"></img></li>
      <li className="flex p-1 my-4 hover:bg-yellow-300"><p className="flex-grow">Champion</p><img className="mx-4" src="champion.png"></img></li>
    </ul>
  </div>
}
const Home: NextPage = (props) => {
  return (
    <>
      <Head>
        <title>Create T3 App</title>
        <meta name="description" content="Generated by create-t3-app" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div className="bg-black">
        <World></World>
      </div>
    </>
  );
};

export default Home;