const state = {
    theme: localStorage.getItem('theme') ?? 'dart',
    language: localStorage.getItem('language') ?? 'en',
    token: localStorage.getItem('token') ?? '',
    userId: localStorage.getItem('userId') ?? 0,
    enableVim: localStorage.getItem('enableVim') === 'true',
    wsConnected: false,
};
const mutations = {
    setTheme(state: any, theme: string) {
        state.theme = theme;
        localStorage.setItem('theme', theme);
        const dart = theme == 'dark';
        document.body.style.backgroundColor = dart ? '#121212' : 'white';
        const root = document.documentElement;
        if (dart) {
            root.style.setProperty('--nut-cell-box-shadow', 'none');
            root.style.setProperty('--nut-navbar-box-shadow', 'none');
            root.style.setProperty('--nut-grid-border-color', '#5a5a5a');
            root.style.setProperty('--history-background-color', '#000000');
            root.style.setProperty('--history-finish-color', '#53b9ff');
            root.style.setProperty('--history-normal-color', 'wheat');
            root.style.setProperty('--history-input-right-color', '#5fff67');
        } else {
            root.style.removeProperty('--nut-cell-box-shadow');
            root.style.removeProperty('--nut-navbar-box-shadow');
            root.style.removeProperty('--nut-grid-border-color');
            root.style.removeProperty('--history-background-color');
            root.style.removeProperty('--history-finish-color');
            root.style.removeProperty('--history-normal-color');
            root.style.removeProperty('--history-input-right-color');

        }
    },
    setLanguage(state: any, language: string) {
        state.language = language;
        localStorage.setItem('language', language);
    },
    setToken(state: any, token: string) {
        state.token = token;
        localStorage.setItem('token', token);
    },
    setUserId(state: any, userId: int) {
        state.userId = userId;
        localStorage.setItem('userId', userId);
    },
    setWsConnected(state: any, wsConnected: boolean) {
        state.wsConnected = wsConnected;
    },
    setEnableVim(state: any, enableVim: boolean) {
        state.enableVim = enableVim;
        localStorage.setItem('enableVim', String(enableVim));
    },
};

const actions = {
    updateTheme({commit}: any, theme: string) {
        commit('setTheme', theme);
    },
    updateLanguage({commit}: any, language: string) {
        commit('setLanguage', language);
    },
    updateUser({commit}: any, user: object) {
        commit('setToken', user.token);
        commit('setUserId', user.userId);
    },
    updateWsConnected({commit}: any, wsConnected: boolean) {
        commit('setWsConnected', wsConnected);
    },
    updateEnableVim({commit}: any, enableVim: boolean) {
        commit('setEnableVim', enableVim);
    },
};

const getters = {
    currentTheme: (state: any) => state.theme,
    currentLanguage: (state: any) => state.language,
    currentToken: (state: any) => state.token,
    currentUserId: (state: any) => state.userId,
    currentWsConnected: (state: any) => state.wsConnected,
    currentEnableVim: (state: any) => state.enableVim,
};

export default {
    state,
    mutations,
    actions,
    getters,
};