import {createI18n} from 'vue-i18n';

const messages = {
    en: {
        dartMode: 'Dart Mode',
        settings: 'Settings',
        login: 'Login',
        home: 'Home',
        userName: 'User Name',
        inputUserName: 'Please input user name',
        inputUserNameTip: 'User name can only be 2 to 5 uppercase letters',
        inputPassword: 'Please input password',
        inputPasswordTip: 'Passwords must be at least 6 to 30 characters long',
        password: 'Password',
        tips: 'Tips',
        userNameOrPasswordError: 'The user name or password is incorrect',
        reconnect: 'Reconnecting...',
        pleaseInputGameNumber: 'Please enter the game number.',
        confirm: 'Confirm',
        cancel: 'Cancel',
        gameEntryCodeError: 'Please enter the right game number.',
    },
    zh: {
        dartMode: '深色模式',
        settings: '设置',
        login: '登录',
        home: '首页',
        userName: '用户名',
        inputUserName: '请输入用户名',
        inputUserNameTip: '用户名只能是2到5个大写字母',
        inputPassword: '请输入密码',
        inputPasswordTip: '密码至少6个字符到30个字符',
        password: '密码',
        tips: '提示',
        userNameOrPasswordError: '用户名或密码错误',
        reconnect: '重连中...',
        pleaseInputGameNumber: '请输入游戏编号',
        confirm: '确定',
        cancel: '取消',
        gameEntryCodeError: '请输入正确的游戏编号',
    },
};

export const i18n = createI18n({
    legacy: false,
    locale: 'en',
    messages,
});