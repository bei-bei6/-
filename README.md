# MATLAB 燃气轮机 Web App

这是一个基于 MATLAB Runtime 的燃气轮机仿真项目，仓库内包含：

- MATLAB 工程与参数数据
- FastAPI 后端
- React + Vite 前端

网页端会通过 Python 调用 MATLAB 打包模块，支持：

- 设计点计算
- 稳态计算
- 动态计算

## 目录说明

```text
repo-root
|- MATLAB* source dir      # MATLAB 源码目录，实际目录名以 MATLAB 开头
|- webapp
|  |- backend              # FastAPI 后端
|  `- frontend             # React + Vite 前端
|- run_main_ds.ps1         # 动态模型直接运行脚本
`- run_main_ss.ps1         # 稳态模型直接运行脚本
```

## 环境要求

启动网页前，请先确保本机具备以下环境：

- Windows
- Python 3.10
- Node.js 与 npm
- MATLAB Runtime R2022b

MATLAB Runtime 默认检查路径为：

```text
C:\Program Files\MATLAB\MATLAB Runtime\R2022b
```

## 端口说明

- 前端页面：`http://127.0.0.1:5173`
- 后端接口：`http://127.0.0.1:8000`

## 网页启动方式

### 第一次启动

适用场景：
第一次克隆仓库，或者本机还没有安装这个项目需要的 Python 依赖、MATLAB 打包模块、前端依赖。

操作说明：
在仓库根目录打开 PowerShell，直接整段复制执行。

```powershell
$RepoRoot = (Get-Location).Path
$MatlabProjectDir = Get-ChildItem -Path $RepoRoot -Directory | Where-Object { $_.Name -like 'MATLAB*' } | Select-Object -First 1 -ExpandProperty FullName

if (-not (Test-Path "C:\Program Files\MATLAB\MATLAB Runtime\R2022b")) {
    throw "MATLAB Runtime R2022b not found: C:\Program Files\MATLAB\MATLAB Runtime\R2022b"
}

if (-not $MatlabProjectDir) {
    throw "MATLAB source directory not found under repository root."
}

py -3.10 -m venv .venv-webapp
.\.venv-webapp\Scripts\python.exe -m pip install --upgrade pip setuptools wheel

.\.venv-webapp\Scripts\python.exe -m pip install -r ".\webapp\backend\requirements.txt"
.\.venv-webapp\Scripts\python.exe -m pip install "$MatlabProjectDir\pack1\python_Main_SS\for_testing"
.\.venv-webapp\Scripts\python.exe -m pip install "$MatlabProjectDir\pack1\python_Main_DS\for_testing"
.\.venv-webapp\Scripts\python.exe -m pip install "$MatlabProjectDir\pack1\python_DESIGN_POINT\for_testing"

npm --prefix ".\webapp\frontend" install

Start-Process powershell -ArgumentList '-NoExit', '-Command', "Set-Location `"$RepoRoot\webapp\backend`"; & `"$RepoRoot\.venv-webapp\Scripts\python.exe`" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000"
Start-Process powershell -ArgumentList '-NoExit', '-Command', "Set-Location `"$RepoRoot\webapp\frontend`"; npm run dev"

Start-Process "http://127.0.0.1:5173"
```

执行后会发生什么：

- 新建本地虚拟环境 `.venv-webapp`
- 安装后端依赖
- 安装 3 个 MATLAB 打包出来的 Python 包
- 安装前端依赖
- 自动启动后端和前端
- 自动打开浏览器页面

### 以后启动

适用场景：
你已经完成过一次依赖安装，现在只想再次启动网页。

操作说明：
在仓库根目录打开 PowerShell，直接整段复制执行。

```powershell
$RepoRoot = (Get-Location).Path

Start-Process powershell -ArgumentList '-NoExit', '-Command', "Set-Location `"$RepoRoot\webapp\backend`"; & `"$RepoRoot\.venv-webapp\Scripts\python.exe`" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000"
Start-Process powershell -ArgumentList '-NoExit', '-Command', "Set-Location `"$RepoRoot\webapp\frontend`"; npm run dev"

Start-Process "http://127.0.0.1:5173"
```

### 分开启动前后端

如果你不想自动弹出两个新 PowerShell 窗口，也可以手动分开启动。

先启动后端：

```powershell
Set-Location .\webapp\backend
& "..\..\.venv-webapp\Scripts\python.exe" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

如果你当前不在 `webapp\backend` 目录，也可以直接在仓库根目录执行：

```powershell
& ".\.venv-webapp\Scripts\python.exe" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000 --app-dir .\webapp\backend
```

再启动前端：

```powershell
Set-Location .\webapp\frontend
npm run dev
```

然后浏览器访问：

```text
http://127.0.0.1:5173
```

## 后端运行机制

后端依赖以下 MATLAB 打包 Python 模块：

- `python_Main_SS`
- `python_Main_DS`
- `python_DESIGN_POINT`

这些包安装自：

```text
<MATLAB source dir>\pack1\...\for_testing
```

后端在调用 worker 前会自动把 MATLAB Runtime 路径注入到 `PATH`。

## 提交代码前需要注意

### 哪些文件是运行时会被改写的

网页运行或计算执行后，以下目录下的部分文件会被改写：

- `<MATLAB source dir>\parameter\*.mat`
- `<MATLAB source dir>\result\*.mat`

其中尤其需要注意的是：

- `py_main_ss.mat`
- `py_main_ds.mat`
- `py_designpoint.mat`
- `dp.mat`
- `scale.mat`
- `x0.mat`
- `x0_sheet.mat`
- `MAP.mat`
- `RESULT.mat`

这些文件里有两类情况：

- 有些是项目运行依赖的基线数据，仓库里需要保留
- 有些会在运行后变成“当前一次计算结果”，不适合作为日常提交内容

如果你准备提交到 GitHub，建议先执行 `git status`，确认这些 `.mat` 改动是不是你有意保留的结果。

### 哪些文件通常不建议提交

以下内容通常属于本地环境、运行输出或构建产物，不建议提交：

- `.venv-webapp/`
- `.claude/`
- `output/`
- `webapp/frontend/node_modules/`
- `webapp/frontend/dist/`
- `webapp/backend/data/` 下的临时文件
- MATLAB 打包目录中的 `build/`、`dist/`、`*.log`
- `parameter/*.backup.mat`
- 新生成的 `result/*.mat`

注意：
当前仓库里有一部分 `.mat`、`build` 产物已经被 Git 跟踪了。仅仅写入 `.gitignore` 不会自动把它们从版本控制里移除；如果后续你想把它们真正移出仓库，需要额外执行 `git rm --cached ...`。

## 主要入口文件

- 前端依赖定义：`webapp/frontend/package.json`
- 前端开发配置：`webapp/frontend/vite.config.ts`
- 后端入口：`webapp/backend/app/main.py`
- 后端运行逻辑：`webapp/backend/app/runner.py`
