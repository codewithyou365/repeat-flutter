export const routes = [
    {
        path: '/game_score',
        component: () => import('../view/game_score.vue'),
    },
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
        path: '/game',
        component: () => import('../view/game.vue'),
        children: [
            {
                path: 'type-game',
                component: () => import('../view/game/type-game.vue'),
            },
            {
                path: 'blank-it-right-game',
                component: () => import('../view/game/blank-it-right-game.vue'),
            },
            {
                path: 'input-game',
                component: () => import('../view/game/input-game.vue'),
            },
        ]
    },

];