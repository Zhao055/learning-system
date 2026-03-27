# 部署记录

由 AI-Native Deploy Kit 自动维护。每次 `/deploy` 执行后自动追加记录。

---

## 部署 learning-system (知芽) — 2026-03-27 11:16:36

| 项目 | 值 |
|------|------|
| 应用 | learning-system (知芽) |
| 时间 | 2026-03-27 11:16:36 |
| 版本 | `initial` |
| Git | `34fcb4e` |
| 操作人 | deploy |
| 状态 | SUCCESS |
| 上一版本 | — |

### 容器状态

```
NAME           IMAGE                          SERVICE        STATUS       PORTS
zhiya-server   learning-system-zhiya-server   zhiya-server   Up (healthy) 0.0.0.0:5820->3000/tcp
```

### 备注

首次部署。Hono + SQLite 单服务，资源限制 256M 内存 / 0.5 CPU。API Key 全部留空（按需使用，不影响启动）。SQLite 数据通过 volume 挂载 `./zhiya-server/data:/app/data` 持久化。对外端口 5820。
