# 知芽 (Zhiya) 部署清单

## 基本信息

| 项目 | 值 |
|------|------|
| 仓库路径 | `/opt/learning-system` |
| Compose 文件 | `docker-compose.yml` |
| Env 文件 | `.env.production` |
| 镜像来源 | `本地构建` |
| 日志文件 | `DEPLOYMENT_LOGBOOK.md` |

## 部署方式

### 方式 B: 本地构建

```
docker compose up --build -d
```

后端是 Hono (Node.js) + SQLite，无需外部数据库服务。iOS 客户端不参与服务端部署。

## 服务清单

| 服务 | 端口 | 健康检查 | 说明 |
|------|------|---------|------|
| zhiya-server | 3000 | `curl -sf http://localhost:3000/health` | Hono API 服务，SQLite 嵌入式数据库 |

## 架构说明

- **后端**: Hono (TypeScript) + better-sqlite3 + Drizzle ORM
- **客户端**: HarmonyOS (ArkTS) — 不部署在服务端
- **AI 网关**: 三选一降级链 Synapse > Claude > MiniMax，至少配一个；客户端也支持 direct 模式（用户自填 Key 绕过服务端）
- **数据库**: SQLite，数据文件在 `zhiya-server/data/` 目录，**必须持久化挂载**

## 已知陷阱

1. **SQLite 数据丢失**: 容器重建后 SQLite 数据库文件会丢失。`docker-compose.yml` 中必须将 `./zhiya-server/data` 挂载为 volume，否则用户数据全部清空
2. **端口 3000 冲突**: 默认端口 3000 是常用端口，服务器上可能被其他服务占用。通过 `PORT` 环境变量修改，同时更新 compose 端口映射
3. **.npmrc 私有源**: 项目有 `.npmrc` 文件配置了包源，Docker 构建时已 COPY 进去，但如果源不可达会导致 `npm ci` 失败。检查 `.npmrc` 内容确认源地址可访问
4. **AI Key 至少配一个**: 服务端 AI 网关按 Synapse > Claude > MiniMax 优先级降级，三个都没配则 chat 接口 500。但客户端有 direct 模式可绕过服务端（用户自填 MiniMax Key）

## 前置条件

- 服务器需安装 Docker + Docker Compose
- AI Key 至少配一个（Synapse / Claude / MiniMax 三选一，见 `.env.production.example`）
- 端口 3000（或自定义端口）未被占用

## 部署后验证

```bash
# 健康检查
curl -sf http://localhost:3000/health

# 确认 API 可达
curl -sf http://localhost:3000/
```
