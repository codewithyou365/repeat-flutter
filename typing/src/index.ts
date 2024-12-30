import { createApp } from 'vue';
import App from './App.vue';
import router from './router';
import store from './store';
import { i18n } from './i18n';

import NutUI from "@nutui/nutui";
import "@nutui/nutui/dist/style.css";
import './index.css';

const app = createApp(App);

app.use(router);
app.use(store);
app.use(NutUI);
app.use(i18n);
app.mount('#root');
