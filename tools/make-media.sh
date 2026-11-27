#!/usr/bin/env bash
# 배경 영상 재편집 + 이미지 최적화.
# 원본은 기존 HYP 저장소(hypkorea.com 복원본)에서 읽고, 결과만 이 저장소 img/ 에 쓴다.
# 다시 만들 때: bash tools/make-media.sh [원본 img 폴더]
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

# 메인: 호텔 라이프스타일 — 수영장 조식 · 풀사이드 · 캔들 · 와인잔 (원본 57초 몽타주에서 발췌)
make_loop main "$SRC/main_video02.mp4" "14.0 4.6" "21.0 4.6" "35.0 4.6" "50.0 4.6"
# 호텔·인력: 원본 영상은 사무실 노트북 장면이라 호텔 서비스와 맞지 않아, 메인 원본의 로비·레스토랑·티 서비스 장면으로 교체
make_loop manpower "$SRC/main_video02.mp4" "0.6 5.2" "8.2 4.6" "27.6 4.6"
# 방역: 마스크(코로나 시기) 장면은 빼고 손 소독·손 씻기만
make_loop disinfection "$SRC/disinfection/main_video.mp4" "3.6 4.4" "8.0 4.2" "12.8 4.6"

# 이미지: 긴 변 1920px로 제한 + 재압축(JPG, 구형 브라우저용) + AVIF(최신 브라우저용)
# build.py 가 같은 이름의 .avif 가 있으면 <picture> 로 감싸 자동 사용한다.
# 다시 실행해도 화질이 계속 깎이지 않도록, 원본 저장소에 같은 파일이 있으면 항상 원본에서 새로 만든다.
find "$OUT" -name "*.jpg" ! -path "*/poster/*" ! -path "*/disinfection/cert*" | while read -r f; do
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
