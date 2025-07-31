# 当前工作目录
CURDIR           := $(shell pwd)

# 输出目录和工具目录
BUILDDIR         := $(CURDIR)/build
GOBIN            := $(CURDIR)/bin

# gomobile 与绑定命令
GOMOBILE         := $(GOBIN)/gomobile
GOBIND           := env PATH="$(GOBIN):$(PATH)" "$(GOMOBILE)" bind

# 引用路径
IMPORT_HOST      := github.com
IMPORT_PATH      := $(IMPORT_HOST)/Jigsaw-Code/outline-go-tun2socks

# XGO 配置（Linux/Windows 构建）
XGO              := $(GOBIN)/xgo
TUN2SOCKS_VERSION := v1.14.2
XGO_LDFLAGS      := '-s -w -X main.version=$(TUN2SOCKS_VERSION)'
ELECTRON_PKG     := outline/electron

.PHONY: all update-gomobile android intra apple linux windows clean clean-all
all: update-gomobile android intra apple linux windows

# --------------------------------------------------------------------
# 安装或更新 gomobile
# --------------------------------------------------------------------
update-gomobile:
	@echo "=> 安装/更新 gomobile 到最新版本…"
	env GOBIN="$(GOBIN)" go install golang.org/x/mobile/cmd/gomobile@latest
	@echo "=> 初始化 gomobile 环境…"
	env PATH="$(GOBIN):$(PATH)" "$(GOMOBILE)" init

$(GOMOBILE): update-gomobile

# --------------------------------------------------------------------
# Android 构建
# --------------------------------------------------------------------
android: $(BUILDDIR)/android/tun2socks.aar

$(BUILDDIR)/android/tun2socks.aar: $(GOMOBILE)
	mkdir -p "$$(dirname $@)"
	$(GOBIND) \
	  -target=android \
	  -a \
	  -ldflags '-w' \
	  -work \
	  -o $@ \
	  $(IMPORT_PATH)/outline/tun2socks \
	  $(IMPORT_PATH)/outline/shadowsocks

# --------------------------------------------------------------------
# Intra 构建（含 doh/split/protect）
# --------------------------------------------------------------------
intra: $(BUILDDIR)/intra/tun2socks.aar

$(BUILDDIR)/intra/tun2socks.aar: $(GOMOBILE)
	mkdir -p "$$(dirname $@)"
	$(GOBIND) \
	  -target=android \
	  -a \
	  -ldflags '-w' \
	  -work \
	  -o $@ \
	  $(IMPORT_PATH)/intra \
	  $(IMPORT_PATH)/intra/android \
	  $(IMPORT_PATH)/intra/doh \
	  $(IMPORT_PATH)/intra/split \
	  $(IMPORT_PATH)/intra/protect

# --------------------------------------------------------------------
# Apple 平台 XCFramework（iOS + Simulator + macOS + Catalyst）
# --------------------------------------------------------------------
apple: $(BUILDDIR)/apple/Tun2socks.xcframework

$(BUILDDIR)/apple/Tun2socks.xcframework: $(GOMOBILE)
	mkdir -p "$(BUILDDIR)/apple"
	env MACOSX_DEPLOYMENT_TARGET=10.14 \
	$(GOBIND) \
	  -target=ios,iossimulator \
	  -iosversion=13.0 \
	  -ldflags '-s -w' \
	  -o $@ \
	  $(IMPORT_PATH)/apple

# --------------------------------------------------------------------
# Linux 构建
# --------------------------------------------------------------------
LINUX_BUILDDIR := $(BUILDDIR)/linux

linux: $(LINUX_BUILDDIR)/tun2socks

$(LINUX_BUILDDIR)/tun2socks: $(XGO)
	mkdir -p "$(LINUX_BUILDDIR)/$(IMPORT_PATH)"
	$(XGO) \
	  -ldflags $(XGO_LDFLAGS) \
	  --targets=linux/amd64 \
	  -dest "$(LINUX_BUILDDIR)" \
	  -pkg $(ELECTRON_PKG) \
	  .
	mv "$(LINUX_BUILDDIR)/$(IMPORT_PATH)-linux-amd64" "$@"
	rm -rf "$(LINUX_BUILDDIR)/$(IMPORT_HOST)"

# --------------------------------------------------------------------
# Windows 构建
# --------------------------------------------------------------------
WINDOWS_BUILDDIR := $(BUILDDIR)/windows

windows: $(WINDOWS_BUILDDIR)/tun2socks.exe

$(WINDOWS_BUILDDIR)/tun2socks.exe: $(XGO)
	mkdir -p "$(WINDOWS_BUILDDIR)/$(IMPORT_PATH)"
	$(XGO) \
	  -ldflags $(XGO_LDFLAGS) \
	  --targets=windows/386 \
	  -dest "$(WINDOWS_BUILDDIR)" \
	  -pkg $(ELECTRON_PKG) \
	  .
	mv "$(WINDOWS_BUILDDIR)/$(IMPORT_PATH)-windows-386.exe" "$@"
	rm -rf "$(WINDOWS_BUILDDIR)/$(IMPORT_HOST)"

# --------------------------------------------------------------------
# 工具安装依赖：xgo
# --------------------------------------------------------------------
$(XGO): go.mod
	env GOBIN="$(GOBIN)" go install github.com/crazy-max/xgo@latest

go.mod: tools.go
	go mod tidy
	touch go.mod

# --------------------------------------------------------------------
# 清理命令
# --------------------------------------------------------------------
clean:
	rm -rf "$(BUILDDIR)"
	go clean

clean-all: clean
	rm -rf "$(GOBIN)"