#!/usr/bin/env bash
# 배경 영상 재편집 + 이미지 최적화.
# 원본은 기존 HYP 저장소(hypkorea.com 복원본)에서 읽고, 결과만 이 저장소 img/ 에 쓴다.
# 다시 만들 때: bash tools/make-media.sh [원본 img 폴더]
#   MEDIA=original bash tools/make-media.sh  → 외부 소재 없이 기존 원본만으로 영상 생성
#
# 필요: ffmpeg(libx264), macOS sips(AVIF 쓰기 지원)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/../hypkorea-site/img}"
OUT="$ROOT/img"
mkdir -p "$OUT/video" "$OUT/poster"

# 모든 배경 영상에 같은 톤 — 채도 살짝 낮추고 따뜻하게, 브랜드 골드와 어울리게
GRADE="eq=saturation=0.88:contrast=1.04:brightness=-0.01,colorbalance=rs=0.03:gs=0.01:bs=-0.04:rm=0.02:bm=-0.02"
XF=0.7   # 장면 사이 크로스페이드(초)

# make_loop 출력이름 원본 "시작 길이" ...
# 장면 시작점은 ffmpeg scene 검출(select=gt(scene,0.3))로 찾은 컷 사이 구간에서 골랐다.
make_loop() {
  local name=$1 src=$2; shift 2
  local inputs=() filters="" i=0 prev="" offset=0 len
  for seg in "$@"; do
    read -r ss len <<<"$seg"
    inputs+=(-ss "$ss" -t "$len" -i "$src")
    filters+="[$i:v]fps=25,scale=1280:720:flags=lanczos,setsar=1,$GRADE,format=yuv420p,settb=AVTB,setpts=PTS-STARTPTS[v$i];"
    i=$((i+1))
  done
  # 크로스페이드 체인
  prev="v0"; offset=0
  local first_len; read -r _ first_len <<<"$1"; offset=$(echo "$first_len - $XF" | bc)
  for ((k=1; k<i; k++)); do
    read -r _ len <<<"${@:$((k+1)):1}"
    filters+="[$prev][v$k]xfade=transition=fade:duration=$XF:offset=$offset[x$k];"
    prev="x$k"; offset=$(echo "$offset + $len - $XF" | bc)
  done
  local total; total=$(echo "$offset + $XF" | bc)
  # 루프 이음새가 튀지 않게 앞뒤로 짧게 페이드
  filters+="[$prev]fade=t=in:st=0:d=0.5,fade=t=out:st=$(echo "$total - 0.5" | bc):d=0.5,format=yuv420p[out]"
  ffmpeg -loglevel error -y "${inputs[@]}" -filter_complex "$filters" -map "[out]" -an \
    -c:v libx264 -preset slow -crf 25 -profile:v high -pix_fmt yuv420p -movflags +faststart "$OUT/video/$name.mp4"
  ffmpeg -loglevel error -y -ss 1.2 -i "$OUT/video/$name.mp4" -frames:v 1 -q:v 4 "$OUT/poster/$name.jpg"
  printf "video %-14s %5.1fs %6s KB\n" "$name" "$total" "$(( $(stat -f%z "$OUT/video/$name.mp4") / 1024 ))"
}

# make_loop_multi 출력이름 "mixkit_id 시작 길이" ... — 소재마다 다른 파일에서 구간을 잘라 이어 붙인다
make_loop_multi() {
  local name=$1; shift
  local inputs=() filters="" i=0 prev offset len total
  for seg in "$@"; do
    read -r id ss len <<<"$seg"
    inputs+=(-ss "$ss" -t "$len" -i "$(fetch "$id")")
    filters+="[$i:v]fps=25,scale=1280:720:flags=lanczos,setsar=1,$GRADE,format=yuv420p,settb=AVTB,setpts=PTS-STARTPTS[v$i];"
    i=$((i+1))
  done
  read -r _ _ len <<<"$1"; offset=$(echo "$len - $XF" | bc); prev="v0"
  for ((k=1; k<i; k++)); do
    read -r _ _ len <<<"${@:$((k+1)):1}"
    filters+="[$prev][v$k]xfade=transition=fade:duration=$XF:offset=$offset[x$k];"
    prev="x$k"; offset=$(echo "$offset + $len - $XF" | bc)
  done
  total=$(echo "$offset + $XF" | bc)
  filters+="[$prev]fade=t=in:st=0:d=0.5,fade=t=out:st=$(echo "$total - 0.5" | bc):d=0.5,format=yuv420p[out]"
  ffmpeg -loglevel error -y "${inputs[@]}" -filter_complex "$filters" -map "[out]" -an \
    -c:v libx264 -preset slow -crf 25 -profile:v high -pix_fmt yuv420p -movflags +faststart "$OUT/video/$name.mp4"
  ffmpeg -loglevel error -y -ss 1.2 -i "$OUT/video/$name.mp4" -frames:v 1 -q:v 4 "$OUT/poster/$name.jpg"
  printf "video %-14s %5.1fs %6s KB\n" "$name" "$total" "$(( $(stat -f%z "$OUT/video/$name.mp4") / 1024 ))"
}

# ---------------------------------------------------------------------------
# 배경 영상 — MEDIA=stock(기본): 외부 무료 소재(tools/stock.tsv) / MEDIA=original: 기존 사이트 원본만 (v1.3.0과 동일)
# 외부 소재를 걷어낼 때는 MEDIA=original 로 다시 돌리면 영상은 같은 경로에 원본 버전으로 바뀐다.
# ---------------------------------------------------------------------------
MEDIA="${MEDIA:-stock}"
CACHE="$ROOT/.media-cache"   # 외부 소재 원본(720p) 캐시 — git에 올리지 않음
fetch() {                    # fetch <mixkit id> → 캐시 경로 출력
  local id=$1 f="$CACHE/$1.mp4"
  mkdir -p "$CACHE"
  [ -s "$f" ] || curl -sf -o "$f" "https://assets.mixkit.co/videos/$id/$id-720.mp4"
  echo "$f"
}

if [ "$MEDIA" = "stock" ]; then
  # 메인: 커튼을 여는 실루엣 → 우아한 복도 → 객실 패닝 → 호텔 조식 (하루의 시작 같은 흐름)
  make_loop_multi main "22240 1.5 6" "34613 0 4.8" "4196 3 6" "15642 2 5"
  # 호텔·인력: 트레이를 든 스태프 → 라테 아트 → 바텐더 골드 셰이커 → 에스프레소 스팀 — 서비스 디테일 위주
  # (v1.5.0까지 쓰던 프런트 체크인 36736은 인물·색감이 어색하다는 피드백으로 제외)
  make_loop_multi manpower "813 3.5 6" "41858 1 5" "4173 6 5" "3575 3 5"
  # 방역: 전문 장비 스팀 청소 → 패브릭 청소 → 정돈된 객실(결과)
  make_loop_multi disinfection "45041 3 5" "34661 1 5" "4030 4 5.5"
else
  # 메인: 호텔 라이프스타일 — 수영장 조식 · 풀사이드 · 캔들 · 와인잔 (원본 57초 몽타주에서 발췌)
  make_loop main "$SRC/main_video02.mp4" "14.0 4.6" "21.0 4.6" "35.0 4.6" "50.0 4.6"
  # 호텔·인력: 원본 영상은 사무실 노트북 장면이라 호텔 서비스와 맞지 않아, 메인 원본의 로비·레스토랑·티 서비스 장면으로 교체
  make_loop manpower "$SRC/main_video02.mp4" "0.6 5.2" "8.2 4.6" "27.6 4.6"
  # 방역: 마스크(코로나 시기) 장면은 빼고 손 소독·손 씻기만
  make_loop disinfection "$SRC/disinfection/main_video.mp4" "3.6 4.4" "8.0 4.2" "12.8 4.6"
fi

# 외부 소재 정지 이미지 — 영상 프레임을 뽑아 사진으로 쓴다 (영상과 색감 통일).
# 매번 캐시 원본에서 새로 뽑으므로 반복 압축 손실이 없다. 형식: 파일명 id 시점(초)
if [ "$MEDIA" = "stock" ]; then
  mkdir -p "$OUT/stock"
  while read -r name id t; do
    ffmpeg -loglevel error -y -ss "$t" -i "$(fetch "$id")" -frames:v 1 \
      -vf "eq=saturation=0.92:contrast=1.03,colorbalance=rs=0.02:bs=-0.03,format=yuvj444p" -q:v 3 "$OUT/stock/$name.jpg"
    sips -s format avif -s formatOptions 62 "$OUT/stock/$name.jpg" --out "$OUT/stock/$name.avif" >/dev/null
  done <<'LIST'
housekeeping 21906 7.5
waiter-order 24405 9
corridor 34613 2.5
steam-clean 45041 4
sofa-clean 34661 6
room-towels 4030 8.5
training 42666 2
workshop 48712 10
golf-hotel 22564 1
skyline-meeting 13218 5
handshake 30013 6.5
boutique-room 4046 3
bar 4043 8
curtains 22240 4.5
LIST
  echo "stills: $(ls "$OUT"/stock/*.jpg | wc -l | tr -d ' ')"
fi

# 이미지: 긴 변 1920px로 제한 + 재압축(JPG, 구형 브라우저용) + AVIF(최신 브라우저용)
# build.py 가 같은 이름의 .avif 가 있으면 <picture> 로 감싸 자동 사용한다.
# 다시 실행해도 화질이 계속 깎이지 않도록, 원본 저장소에 같은 파일이 있으면 항상 원본에서 새로 만든다.
find "$OUT" -name "*.jpg" ! -path "*/poster/*" ! -path "*/stock/*" ! -path "*/disinfection/cert*" | while read -r f; do
  src_f="$SRC/${f#"$OUT"/}"; [ -f "$src_f" ] || src_f="$f"
  w=$(sips -g pixelWidth "$src_f" | awk '/pixelWidth/{print $2}')
  resize=(); [ "$w" -gt 1920 ] && resize=(--resampleWidth 1920)
  tmp="${f%.jpg}.tmp.jpg"
  sips -s format jpeg -s formatOptions 78 ${resize[@]+"${resize[@]}"} "$src_f" --out "$tmp" >/dev/null
  # 재압축이 오히려 커지면(이미 작게 압축된 원본) 원본을 그대로 쓴다
  if [ "$(stat -f%z "$tmp")" -lt "$(stat -f%z "$src_f")" ]; then mv "$tmp" "$f"; else rm "$tmp"; [ "$src_f" != "$f" ] && cp "$src_f" "$f"; fi
  # 가로·세로가 홀수면 1px 잘라 짝수로 — sips가 만든 홀수 크기 AVIF는 Chrome에서 디코딩되지 않았다(1920x975에서 확인)
  w=$(sips -g pixelWidth "$f" | awk '/pixelWidth/{print $2}'); h=$(sips -g pixelHeight "$f" | awk '/pixelHeight/{print $2}')
  if [ $((w % 2)) -eq 1 ] || [ $((h % 2)) -eq 1 ]; then
    sips --cropToHeightWidth $((h - h % 2)) $((w - w % 2)) "$f" >/dev/null
  fi
  sips -s format avif -s formatOptions 60 "$f" --out "${f%.jpg}.avif" >/dev/null
done
# 포스터도 AVIF
for f in "$OUT"/poster/*.jpg; do sips -s format avif -s formatOptions 60 "$f" --out "${f%.jpg}.avif" >/dev/null; done
echo "images: $(find "$OUT" -name '*.avif' | wc -l | tr -d ' ') avif"
