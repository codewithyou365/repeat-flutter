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
        path: '/game/type-game',
        component: () => import('../view/game/type-game.vue'),
    },
    {
        path: '/game/blank-it-right-game',
        component: () => import('../view/game/blank-it-right-game.vue'),
    },
    {
        path: '/game/input-game',
        component: () => import('../view/game/input-game.vue'),
    }

];