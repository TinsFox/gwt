# 多阶段构建，减小镜像体积
FROM golang:1.21-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache git make ca-certificates

# 设置工作目录
WORKDIR /app

# 复制 go mod 文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN make build

# 运行时镜像
FROM alpine:latest

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    git \
    bash \
    zsh \
    fish \
    curl \
    && rm -rf /var/cache/apk/*

# 创建非 root 用户
RUN adduser -D -g '' appuser

# 从构建阶段复制二进制文件
COPY --from=builder /app/build/gwt /usr/local/bin/gwt

# 设置用户权限
RUN chmod +x /usr/local/bin/gwt

# 切换到非 root 用户
USER appuser

# 设置工作目录
WORKDIR /workspace

# 默认命令
ENTRYPOINT ["gwt"]
CMD ["--help"]

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD gwt --version || exit 1

# 标签
LABEL maintainer="your-email@example.com" \
      version="0.1.0" \
      description="Git Worktree CLI Tool" \
      org.opencontainers.image.title="gwt" \
      org.opencontainers.image.description="A CLI tool for managing Git worktrees" \
      org.opencontainers.image.version="0.1.0" \
      org.opencontainers.image.licenses="MIT"