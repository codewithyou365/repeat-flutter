import {createRouter, createWebHistory} from 'vue-router';
import {routes} from './router.config';
import {check} from "../api/bus";

const router = createRouter({
    history: createWebHistory(),
    routes,
});

router.beforeEach((to, _, next) => {
    if (!check() && to.path !== "/loading") {
        next("/loading");
    } else {
        next();
    }
});
export default router;