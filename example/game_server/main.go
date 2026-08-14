// 游戏订阅服务器的最小 mock，只用标准库，用来联调 App 的「订阅游戏 / 检查更新」。
//
// 启动（仓库根目录没有 go.mod，所以进到本目录里跑）：
//
//	cd example/game_server && go run .                       # 监听 :8080，包目录 ./games
//	cd example/game_server && go run . -addr :9000 -dir /tmp/games
//
// 包目录里放的就是 typing/gen.sh 产出的 dist.zip，改个名即可：
//
//	mkdir -p example/game_server/games
//	cp typing/dist.zip example/game_server/games/typing.zip
//
// zip 里必须有一份 manifest.json（见 typing/public/manifest.json）。服务器不自己维护版本，
// 版本号一律以包内 manifest 的 "version" 为准，改版本就是改 typing/public/manifest.json 后重新打包。
//
// 三个接口：
//
//	GET /                        列出已发现的包和版本（浏览器里能直接看，方便确认地址通了）
//	GET /{name}/manifest.json    包内 manifest，额外注入 "zip"（相对地址）和 "hash"（zip 的 sha1）
//	GET /{name}/{name}.zip       zip 本体
//
// app 里「订阅地址」要填电脑的局域网 IP，比如 http://192.168.1.5:8080/typing/manifest.json，
// 手机上填 127.0.0.1 是连不到电脑的。
package main

import (
	"archive/zip"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

// bundle 是一个包的解析结果：包内 manifest 原样保留成 map，这样包里多写的字段能原样透出去。
type bundle struct {
	name     string
	zipPath  string
	size     int64
	modTime  time.Time
	manifest map[string]any
	hash     string
}

func (b *bundle) version() int64 {
	switch v := b.manifest["version"].(type) {
	case float64:
		return int64(v)
	case string:
		return 0
	}
	return 0
}

// 解析结果按 zip 的 mtime+size 缓存，改了包不用重启服务器。
type store struct {
	dir string
	mu  sync.Mutex
	m   map[string]*bundle
}

func newStore(dir string) *store {
	return &store{dir: dir, m: map[string]*bundle{}}
}

// get 返回名为 name 的包。zip 变了（mtime 或 size 变化）就重新解析。
func (s *store) get(name string) (*bundle, error) {
	if name == "" || strings.ContainsAny(name, `/\.`) {
		return nil, fmt.Errorf("bad bundle name: %q", name)
	}
	zipPath := filepath.Join(s.dir, name+".zip")
	st, err := os.Stat(zipPath)
	if err != nil {
		return nil, err
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	if b, ok := s.m[name]; ok && b.modTime.Equal(st.ModTime()) && b.size == st.Size() {
		return b, nil
	}
	b, err := parseBundle(name, zipPath, st)
	if err != nil {
		return nil, err
	}
	s.m[name] = b
	log.Printf("loaded bundle %s v%d (%s, sha1=%s)", b.name, b.version(), zipPath, b.hash)
	return b, nil
}

// list 扫一遍目录，返回所有能解析出 manifest 的包，按名字排序。
func (s *store) list() []*bundle {
	entries, err := os.ReadDir(s.dir)
	if err != nil {
		log.Printf("read dir %s: %v", s.dir, err)
		return nil
	}
	var ret []*bundle
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".zip") {
			continue
		}
		name := strings.TrimSuffix(e.Name(), ".zip")
		b, err := s.get(name)
		if err != nil {
			log.Printf("skip %s: %v", e.Name(), err)
			continue
		}
		ret = append(ret, b)
	}
	sort.Slice(ret, func(i, j int) bool { return ret[i].name < ret[j].name })
	return ret
}

func parseBundle(name, zipPath string, st os.FileInfo) (*bundle, error) {
	hash, err := sha1File(zipPath)
	if err != nil {
		return nil, err
	}
	zr, err := zip.OpenReader(zipPath)
	if err != nil {
		return nil, err
	}
	defer zr.Close()

	var manifest map[string]any
	for _, f := range zr.File {
		if f.Name != "manifest.json" {
			continue
		}
		rc, err := f.Open()
		if err != nil {
			return nil, err
		}
		data, err := io.ReadAll(rc)
		rc.Close()
		if err != nil {
			return nil, err
		}
		if err := json.Unmarshal(data, &manifest); err != nil {
			return nil, fmt.Errorf("manifest.json in %s: %w", zipPath, err)
		}
		break
	}
	if manifest == nil {
		return nil, fmt.Errorf("no manifest.json in %s", zipPath)
	}
	return &bundle{
		name:     name,
		zipPath:  zipPath,
		size:     st.Size(),
		modTime:  st.ModTime(),
		manifest: manifest,
		hash:     hash,
	}, nil
}

func sha1File(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()
	h := sha1.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

func main() {
	addr := flag.String("addr", ":8080", "监听地址")
	dir := flag.String("dir", "./games", "放 *.zip 的目录")
	flag.Parse()

	abs, err := filepath.Abs(*dir)
	if err != nil {
		log.Fatal(err)
	}
	s := newStore(abs)
	log.Printf("serving bundles from %s", abs)
	for _, b := range s.list() {
		log.Printf("  %s v%d", b.name, b.version())
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", s.handle)
	log.Printf("listening on %s", *addr)
	log.Fatal(http.ListenAndServe(*addr, mux))
}

func (s *store) handle(w http.ResponseWriter, r *http.Request) {
	log.Printf("%s %s", r.Method, r.URL.Path)
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) == 1 && parts[0] == "" {
		s.handleIndex(w)
		return
	}
	if len(parts) != 2 {
		http.NotFound(w, r)
		return
	}
	name, file := parts[0], parts[1]
	b, err := s.get(name)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	switch file {
	case "manifest.json":
		s.handleManifest(w, b)
	case name + ".zip":
		http.ServeFile(w, r, b.zipPath)
	default:
		http.NotFound(w, r)
	}
}

func (s *store) handleIndex(w http.ResponseWriter) {
	type row struct {
		Name    string `json:"name"`
		Version int64  `json:"version"`
		URL     string `json:"manifest"`
	}
	var rows []row
	for _, b := range s.list() {
		rows = append(rows, row{Name: b.name, Version: b.version(), URL: "/" + b.name + "/manifest.json"})
	}
	writeJSON(w, rows)
}

// handleManifest 把包内 manifest 原样吐出去，只额外注入 zip 地址和 sha1 ——
// zip 没法自含自己的 sha1，只能由服务器算。
func (s *store) handleManifest(w http.ResponseWriter, b *bundle) {
	out := make(map[string]any, len(b.manifest)+2)
	for k, v := range b.manifest {
		out[k] = v
	}
	out["zip"] = b.name + ".zip"
	out["hash"] = b.hash
	writeJSON(w, out)
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")
	if err := enc.Encode(v); err != nil {
		log.Printf("write json: %v", err)
	}
}
