export const routes = [
    {
        path: '/',
        redirect: '/login',
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