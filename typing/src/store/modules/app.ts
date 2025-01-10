const state = {
    theme: localStorage.getItem('theme') || 'dart',
    language: localStorage.getItem('language') || 'en',
    token: localStorage.getItem('token') || '',
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
        } else {
            root.style.removeProperty('--nut-cell-box-shadow');
            root.style.removeProperty('--nut-navbar-box-shadow');
            root.style.removeProperty('--nut-grid-border-color');
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
    setWsConnected(state: any, wsConnected: boolean) {
        state.wsConnected = wsConnected;
    },
};

const actions = {
    updateTheme({commit}: any, theme: string) {
        commit('setTheme', theme);
    },
    updateLanguage({commit}: any, language: string) {
        commit('setLanguage', language);
    },
    updateToken({commit}: any, token: string) {
        commit('setToken', token);
    },
    updateWsConnected({commit}: any, wsConnected: boolean) {
        commit('setWsConnected', wsConnected);
    },
};

const getters = {
    currentTheme: (state: any) => state.theme,
    currentLanguage: (state: any) => state.language,
    currentToken: (state: any) => state.token,
    currentWsConnected: (state: any) => state.wsConnected,
};

export default {
    state,
    mutations,
    actions,
    getters,
};