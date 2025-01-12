import axios, {AxiosInstance} from 'axios';

const http: AxiosInstance = axios.create({
    baseURL: `http://${window.location.hostname}:${window.location.port}`,
    timeout: 5000, // 请求超时时间
    headers: {
        'Content-Type': 'application/json',
    },
});

// 请求拦截器
http.interceptors.request.use(
    (config) => {
        // 可以在这里添加 token 等信息
        const token = localStorage.getItem('token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => {
        return Promise.reject(new Error(error.toString()));
    }
);

// 响应拦截器
http.interceptors.response.use(
    (response) => response.data,
    (error) => {
        // 处理错误信息
        console.error('HTTP Error:', error);
        return Promise.reject(new Error(error.toString()));
    }
);

export default http;