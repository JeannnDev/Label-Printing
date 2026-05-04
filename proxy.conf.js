require('dotenv').config();

const PROXY_CONFIG = {
  "/api": {
    "target": process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8080/rest",
    "secure": false,
    "changeOrigin": true,
    "pathRewrite": {
      "^/api": ""
    },
    "headers": {
      "Authorization": process.env.NEXT_PUBLIC_API_AUTHORIZATION || "",
      "EMPRESA": process.env.NEXT_PUBLIC_API_EMPRESA || "01",
      "FILIAL": process.env.NEXT_PUBLIC_API_FILIAL || "0101"
    },
    "logLevel": "debug"
  }
};

module.exports = PROXY_CONFIG;
