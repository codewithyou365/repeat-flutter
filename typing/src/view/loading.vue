<template>
  <div>loading...</div>
</template>

<script setup lang="ts">
import {client, url, Request, Response, ClientStatus} from '../api/ws';
import {onMounted} from 'vue';
import {busReset, bus, EventName, RefreshGameType} from '../api/bus';
import {LocationQueryRaw, useRouter} from "vue-router";

const router = useRouter();
import {useStore} from 'vuex';
import {Path} from "../utils/constant.ts";

const store = useStore();

onMounted(() => {
  busReset();
  client.status = ClientStatus.INIT;
  client.controllers.set(Path.kick, async (_: Request) => {
    client.stop(false, "kicked by server");
    await router.push("/login");
    return new Response();
  });
  client.controllers.set(Path.refreshGame, async (req: Request) => {
    bus().emit(EventName.RefreshGame, RefreshGameType.from(req.data));
    return new Response();
  });

  client.start(url + `?token=${store.getters.currentToken}`, (status: number) => {
    bus().emit(EventName.WsStatus, status);
  }, async () => {
    if (client.node) {
      try {
        return await client.node.send(new Request({path: Path.heart}), false);
      } catch (error) {
        console.error('Error sending heartbeat:', error);
        throw error;
      }
    } else {
      console.error('Client node is unavailable.');
      return Promise.reject(new Error('Client node is unavailable.'));
    }
  });
  bus().on(EventName.WsStatus, async (status: number) => {
    if (status === ClientStatus.CONNECT_FINISH) {
      const req = new Request({path: Path.entryGame, data: 0});
      const res = await client.node!.send(req);
      if (res.error) {
        console.error('Error starting game:', res.error);
      } else {
        const refreshGame = res.data as LocationQueryRaw;
        await router.push({path: "/game", query: refreshGame});
      }
    }
  });

});

</script>