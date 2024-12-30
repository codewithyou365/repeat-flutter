export const routes = [
    {
        path: '/',
        redirect: '/home',
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