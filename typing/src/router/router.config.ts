export const routes = [
    {
        path: '/settings',
        component: () => import('../view/settings.vue'),
    },
    {
        path: '/loading',
        component: () => import('../view/loading.vue'),
    },
    {
        path: '/login',
        component: () => import('../view/login.vue'),
    },
    {
        path: '/home',
        component: () => import('../view/home.vue'),
    },
    {
        path: '/game',
        component: () => import('../view/game.vue'),
    },
    {
        path: '/game-editor',
        component: () => import('../view/game-editor.vue'),
    },

];