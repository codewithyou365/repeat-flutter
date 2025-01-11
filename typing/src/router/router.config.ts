export const routes = [
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
        path: '/settings',
        component: () => import('../view/settings.vue'),
    },
];