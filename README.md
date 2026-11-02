# codysseyE1-1

## 1. 미션 개요

터미널의 파일·권한 조작, Docker 이미지와 컨테이너 운영, Dockerfile 기반 웹 서버 실행, 포트 매핑, 바인드 마운트와 볼륨의 차이를 직접 검증한 기록이다. Git으로 변경을 관리하고 GitHub 저장소에 결과물을 연결했다.

- GitHub 저장소: <https://github.com/sinmodel/codysseyE1-1>
- 웹 서버 소스: [`app/index.html`](./app/index.html)
- Dockerfile: [`Dockerfile`](./Dockerfile)
- GitHub 저장소 화면: [`docs/evidence/github-repository.png`](./docs/evidence/github-repository.png)

## 2. 실행 환경

| 항목 | 사용 환경 |
|---|---|
| OS | Windows 11, Ubuntu 26.04.1 LTS (WSL2) |
| 터미널 / 쉘 | Windows Terminal / Bash (`/bin/bash`) |
| Docker | Docker Desktop 4.97.0, Engine 29.9.2 |
| Git | Ubuntu WSL의 Git 2.53.0 |
| 원격 저장소 | `https://github.com/sinmodel/codysseyE1-1.git`, `main` |

```console
$ docker --version
Docker version 29.9.2, build a82e528

$ git --version
git version 2.53.0

$ docker info --format '{{.ServerVersion}}'
29.9.2
```

## 3. 수행 체크리스트

- [x] 터미널 위치·목록·파일 생성·내용 확인·복사·이동/이름 변경·삭제
- [x] 파일 및 디렉토리 권한 변경과 확인
- [x] Docker 버전 및 데몬 점검, `hello-world` 실행
- [x] Ubuntu 컨테이너 명령 실행, `exec`·중지·삭제 확인
- [x] 이미지/컨테이너 목록, 로그, 리소스 통계 확인
- [x] NGINX 기반 커스텀 Dockerfile 이미지 빌드
- [x] `8080:80` 포트 매핑 후 `curl` 접속 확인
- [x] 바인드 마운트 호스트 파일 변경 반영 확인
- [x] 컨테이너 삭제 후 named volume 데이터 유지 확인
- [x] Git 설정 및 GitHub 원격 저장소 연결 확인
- [ ] VS Code GitHub 로그인 화면 증거 추가

## 4. 터미널 조작 및 권한 로그

아래 로그의 홈 경로에 포함된 Linux 사용자명은 개인정보 보호를 위해 `<linux-user>`로 표시했다.

```console
$ pwd
/home/<linux-user>/workstation

$ ls -la
.  ..  .git  Dockerfile  README.md  app  data  docs

$ mkdir -p docs/terminal-practice
$ printf 'CLI practice note\n' > docs/terminal-practice/note.txt
$ touch docs/terminal-practice/empty.txt
$ cat docs/terminal-practice/note.txt
CLI practice note

$ cp docs/terminal-practice/note.txt docs/terminal-practice/copy.txt
$ mv docs/terminal-practice/copy.txt docs/terminal-practice/renamed.txt
$ ls docs/terminal-practice
empty.txt  note.txt  renamed.txt
$ rm docs/terminal-practice/renamed.txt
$ test ! -e docs/terminal-practice/renamed.txt && echo removed
removed
```

`pwd` 결과는 절대 경로이고, `docs/terminal-practice/note.txt`는 현재 디렉토리를 기준으로 한 상대 경로다.

권한 변경 전후 확인. 실험 후 문서 폴더와 파일은 공유할 수 있도록 원래 접근 모드로 복원했다.

```console
$ stat -c '%A %a %n' docs/terminal-practice docs/terminal-practice/note.txt
drwxr-xr-x 755 docs/terminal-practice
-rw-r--r-- 644 docs/terminal-practice/note.txt

$ chmod 640 docs/terminal-practice/note.txt
$ chmod 700 docs/terminal-practice
$ stat -c '%A %a %n' app data docs/terminal-practice docs/terminal-practice/note.txt
drwxr-xr-x 755 app
drwx------ 700 data
drwx------ 700 docs/terminal-practice
-rw-r----- 640 docs/terminal-practice/note.txt

$ chmod 755 docs/terminal-practice
$ chmod 644 docs/terminal-practice/note.txt
```

`r/w/x`는 읽기/쓰기/실행 권한이다. 숫자 모드는 소유자·그룹·기타 사용자 순서이며 `7 = 4+2+1`(rwx), `5 = 4+1`(r-x), `4 = r--`다. 따라서 `755`는 `rwxr-xr-x`, `640`은 `rw-r-----`를 뜻한다. `data`는 소유자만 접근할 수 있도록 `700`으로 둔다.

## 5. Docker 설치 및 기본 운영 로그

```console
$ docker version
Client: Docker 29.9.2, OS/Arch linux/amd64, Context default
Server: Docker Desktop 4.97.0
Engine: 29.9.2, OS/Arch linux/amd64

$ docker run --rm hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.

$ docker run --rm ubuntu:24.04 bash -lc 'pwd; ls / | head -n 5; echo ubuntu-container-ok'
/
bin
boot
dev
etc
home
ubuntu-container-ok
```

실행 중인 컨테이너에 `exec`로 명령을 실행하고 정리했다.

```console
$ docker run -d --name workstation-ubuntu-lab ubuntu:24.04 sleep infinity
$ docker exec workstation-ubuntu-lab bash -lc 'echo exec-into-running-container'
exec-into-running-container
$ docker stop workstation-ubuntu-lab
workstation-ubuntu-lab
$ docker rm workstation-ubuntu-lab
workstation-ubuntu-lab
```

`docker run`은 컨테이너를 새로 만들고 시작한다. 위의 일회성 `--rm` 실행은 명령이 끝나면 컨테이너를 제거한다. `-d`는 백그라운드에서 계속 실행하고, `exec`는 그 실행 중인 컨테이너에 추가 명령을 실행한다. `stop`은 중지하고 `rm`은 컨테이너를 삭제한다.

```console
$ docker images
hello-world:latest
nginx:latest
nginx:alpine
ubuntu:24.04
workstation-web:v1

$ docker ps -a
workstation-web   workstation-web:v1   Up   0.0.0.0:8080->80/tcp
ecstatic_haibt    hello-world          Exited (0)
trusting_davinci  hello-world          Exited (0)

$ docker logs --tail 3 workstation-web
... "GET / HTTP/1.1" 200 ...

$ docker stats --no-stream workstation-web
CONTAINER            CPU %   MEM USAGE
workstation-web      0.00%   약 14.48MiB
```

## 6. Dockerfile 기반 웹 서버 및 포트 매핑

기존 베이스 이미지 `nginx:alpine`를 사용했다. Dockerfile은 `app/index.html`을 NGINX 기본 웹 루트로 복사해 기본 환영 페이지 대신 과제용 정적 페이지를 제공한다.

```dockerfile
FROM nginx:alpine

LABEL org.opencontainers.image.title="workstation-web"
LABEL org.opencontainers.image.description="Static site for the developer workstation assignment"

COPY app/index.html /usr/share/nginx/html/index.html
```

```console
$ docker build -t workstation-web:v1 .
#8 naming to docker.io/library/workstation-web:v1 done

$ docker run -d --name workstation-web -p 8080:80 workstation-web:v1
$ docker ps --filter name=workstation-web
workstation-web   Up   0.0.0.0:8080->80/tcp

$ curl -fsS http://localhost:8080
<!doctype html>
...
<h1>Developer Workstation</h1>
<p>Custom NGINX image running in Docker.</p>
...
```

컨테이너의 80번 포트를 호스트의 8080번 포트에 연결했다. 접속 검증은 브라우저 대신 `curl` 응답으로 기록했다.

## 7. 바인드 마운트 변경 반영

호스트의 `app/site` 디렉토리를 컨테이너 웹 루트에 읽기 전용으로 연결했다. 호스트 파일 자체를 수정한 뒤 같은 URL의 응답이 바뀌는 것을 확인했다.

```console
$ docker run -d --name workstation-bind -p 8081:80 \
  -v "$PWD/app/site:/usr/share/nginx/html:ro" nginx:alpine
$ curl -fsS http://localhost:8081
<h1>Bind mount: before host edit</h1>

$ printf '<h1>Bind mount: after host edit</h1>\n' > app/site/index.html
$ curl -fsS http://localhost:8081
<h1>Bind mount: after host edit</h1>

$ docker stop workstation-bind
$ docker rm workstation-bind
```

## 8. Docker named volume 영속성

테스트 컨테이너에서 named volume에 파일을 쓴 뒤 해당 컨테이너를 삭제했다. 새 컨테이너에 같은 볼륨을 연결해 파일 내용을 다시 읽었다.

```console
$ docker volume create codyssey-workstation-data
codyssey-workstation-data

$ docker run -d --name workstation-vol-before \
  -v codyssey-workstation-data:/data alpine sleep infinity
$ docker exec workstation-vol-before sh -c \
  'printf "volume-data-survives-container\n" > /data/proof.txt; cat /data/proof.txt'
volume-data-survives-container
$ docker rm -f workstation-vol-before
workstation-vol-before

$ docker run -d --name workstation-vol-after \
  -v codyssey-workstation-data:/data alpine sleep infinity
$ docker exec workstation-vol-after cat /data/proof.txt
volume-data-survives-container
$ docker rm -f workstation-vol-after
workstation-vol-after
```

컨테이너를 삭제해도 named volume은 별도로 남으므로 새 컨테이너에서 같은 데이터를 읽을 수 있다. 확인용 볼륨은 삭제하지 않고 유지 중이다.

## 9. Git / GitHub 설정

```console
$ git config --global init.defaultBranch main
$ git branch --show-current
main

$ git config --list
core.repositoryformatversion=0
core.filemode=true
init.defaultBranch=main
user.name=[REDACTED]
user.email=[REDACTED]
remote.origin.url=https://github.com/sinmodel/codysseyE1-1.git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
branch.main.remote=origin
branch.main.merge=refs/heads/main

$ git remote -v
origin  https://github.com/sinmodel/codysseyE1-1.git (fetch)
origin  https://github.com/sinmodel/codysseyE1-1.git (push)
```

사용자 이름과 이메일은 `git config --list` 요구에 맞춰 기록하되 공개 문서에서는 마스킹했다. Git은 로컬 변경 이력과 커밋을 관리하고, GitHub는 저장소를 원격으로 보관·공유·협업하는 플랫폼이다.

저장소 화면 증거는 [`docs/evidence/github-repository.png`](./docs/evidence/github-repository.png)에서 확인할 수 있다. 이 이미지는 GitHub 저장소 화면이며, VS Code의 GitHub 로그인 화면을 증명하지는 않는다. VS Code 계정 인증 화면은 민감 정보가 보이지 않도록 캡처한 뒤 별도 증거로 추가해야 한다.

## 10. 트러블슈팅

### Docker CLI에서 데몬 연결 실패

- **문제:** PowerShell에서 `docker version`을 실행했을 때 Docker Desktop Linux Engine named pipe에 연결할 수 없었다.
- **원인 가설:** Docker Desktop 엔진이 아직 시작되지 않았거나 WSL2 통합이 준비되지 않았다.
- **확인:** Ubuntu WSL에서 `docker version` 및 `docker info`를 다시 실행해 Client뿐 아니라 Server/Engine 버전이 응답하는지 확인했다.
- **해결:** Docker Desktop을 시작하고 WSL2 Ubuntu 연동 상태에서 명령을 실행했다. 이후 Docker Engine 29.9.2 응답과 컨테이너 실행을 확인했다.

### Git push의 인증 및 원격 이력 충돌

- **문제:** 초기 HTTPS push에서 인증이 거부됐고, 이후 원격 README 때문에 로컬 브랜치 push가 non-fast-forward로 거부됐다.
- **원인 가설:** HTTPS에서 계정 비밀번호 인증은 지원되지 않으며, 원격 저장소에 로컬과 별도로 생성된 커밋이 있었다.
- **확인:** `git remote -v`로 원격 주소를 확인하고, push 거부 메시지에서 원격 이력이 앞서 있음을 확인했다.
- **해결:** 올바른 GitHub 인증 방식으로 로그인한 뒤 `git pull origin main --allow-unrelated-histories --no-rebase`로 이력을 합치고 push했다. 토큰이나 비밀번호는 문서에 저장하지 않았다.

## 11. 핵심 개념 요약

- **이미지와 컨테이너:** 이미지는 실행에 필요한 파일·설정의 템플릿이고, 컨테이너는 그 이미지로 만든 격리된 실행 인스턴스다.
- **포트 매핑:** `-p 8080:80`은 호스트의 8080번 요청을 컨테이너의 80번 웹 서버로 전달한다.
- **바인드 마운트와 볼륨:** 바인드 마운트는 호스트의 특정 경로를 연결해 호스트 변경을 바로 반영한다. named volume은 Docker가 관리하는 저장 공간으로 컨테이너 생명주기와 분리되어 데이터를 보존한다.
- **권한:** `755`는 소유자에게 읽기·쓰기·실행, 다른 사용자에게 읽기·실행을 허용한다. `644`는 소유자에게 읽기·쓰기, 다른 사용자에게 읽기만 허용한다.