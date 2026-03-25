<template>
  <div class="loading-page">
    <div class="loading-text">
      loading<span class="dot dot-1">.</span><span class="dot dot-2">.</span><span class="dot dot-3">.</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import {client, url, Request, Response, ClientStatus} from '../api/ws';
import {onMounted} from 'vue';
import {busReset, bus, EventName} from '../api/bus';
import {useRouter} from "vue-router";

const router = useRouter();
import {useStore} from 'vuex';
import {ContentType, Path} from "../utils/constant.ts";

const store = useStore();

onMounted(() => {
  busReset();
  client.status = ClientStatus.INIT;
  client.controllers.set(Path.kick, async (_: Request) => {
    client.stop(false, "kicked by server");
    await router.push("/login");
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
      const req = new Request({path: Path.contentKey, data: 0});
      const res = await client.node!.send(req);
      if (res.error) {
        if (res.error === 'token-invalid') {
          await router.push("/login");
        } else {
          console.error('Error starting game:', res.error);
        }
      } else {
        const contentType = ContentType.toContentType(res.data);
        await router.push({path: contentType.path});
      }
    }
  });

});

</script>

<style scoped>
.loading-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f7f2e8;
}

.loading-text {
  font-size: 20px;
  letter-spacing: 0.04em;
  color: #2c2218;
}

.dot {
  display: inline-block;
  width: 6px;
  text-align: center;
  animation: loading-bounce 1.2s infinite ease-in-out;
}

.dot-2 {
  animation-delay: 0.15s;
}

.dot-3 {
  animation-delay: 0.3s;
}

@keyframes loading-bounce {
  0%,
  80%,
  100% {
    transform: translateY(0);
    opacity: 0.45;
  }
  40% {
    transform: translateY(-6px);
    opacity: 1;
  }
}

.nut-theme-dark .loading-page {
  background: #1f1b16;
}

.nut-theme-dark .loading-text {
  color: #f2e6d6;
}
</style>
