const state = {
    theme: localStorage.getItem('theme') || 'dart',
    language: localStorage.getItem('language') || 'en',
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
        } else {
            root.style.removeProperty('--nut-cell-box-shadow');
            root.style.removeProperty('--nut-navbar-box-shadow');
        }
    },
    setLanguage(state: any, language: string) {
        state.language = language;
        localStorage.setItem('language', language);
    },
};

const actions = {
    updateTheme({commit}: any, theme: string) {
        commit('setTheme', theme);
    },
    updateLanguage({commit}: any, language: string) {
        commit('setLanguage', language);
    },
};

const getters = {
    currentTheme: (state: any) => state.theme,
    currentLanguage: (state: any) => state.language,
};

export default {
    state,
    mutations,
    actions,
    getters,
};